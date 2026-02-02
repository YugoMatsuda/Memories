import Foundation
import Domains
import Repositories
@preconcurrency import Shared
import APIGateways

public struct MemoryFormUseCase: MemoryFormUseCaseProtocol, @unchecked Sendable {
    private let memoryRepository: MemoryRepositoryProtocol
    private let memoryGateway: MemoryGatewayProtocol
    private let syncQueueService: SyncQueueServiceProtocol
    private let reachabilityRepository: ReachabilityRepositoryProtocol
    private let imageStorageRepository: ImageStorageRepositoryProtocol

    public init(
        memoryRepository: MemoryRepositoryProtocol,
        memoryGateway: MemoryGatewayProtocol,
        syncQueueService: SyncQueueServiceProtocol,
        reachabilityRepository: ReachabilityRepositoryProtocol,
        imageStorageRepository: ImageStorageRepositoryProtocol
    ) {
        self.memoryRepository = memoryRepository
        self.memoryGateway = memoryGateway
        self.syncQueueService = syncQueueService
        self.reachabilityRepository = reachabilityRepository
        self.imageStorageRepository = imageStorageRepository
    }

    public func createMemory(album: Album, title: String, imageData: Data) async -> MemoryFormUseCaseModel.CreateResult {
        let localId = UUID()

        // 1. Save image locally
        let localImagePath: String
        do {
            localImagePath = try imageStorageRepository.save(imageData, entity: .memory, localId: localId)
        } catch {
            return .failure(.imageStorageFailed)
        }

        // 2. Save to local DB (Optimistic)
        let memory = Memory.create(
            serverId: nil,
            localId: localId,
            albumId: album.id,
            albumLocalId: album.localIdUUID,
            title: title,
            imageUrl: nil,
            imageLocalPath: localImagePath,
            createdAt: Date(),
            syncStatus: .pendingCreate
        )
        do {
            try await memoryRepository.insert(memory)
        } catch {
            return .failure(.databaseError)
        }

        // 3. If offline or album not synced, enqueue and return
        guard reachabilityRepository.isConnected else {
            syncQueueService.enqueue(entityType: .memory, operationType: .create, localId: localId)
            return .successPendingSync(memory)
        }

        guard let albumServerId = album.id else {
            // Album not synced yet, enqueue for later
            syncQueueService.enqueue(entityType: .memory, operationType: .create, localId: localId)
            return .successPendingSync(memory)
        }

        // 4. If online and album synced, sync immediately
        return await syncCreate(memory: memory, albumServerId: albumServerId, imageData: imageData)
    }

    // MARK: - Private

    private func syncCreate(memory: Memory, albumServerId: Int, imageData: Data) async -> MemoryFormUseCaseModel.CreateResult {
        do {
            let response = try await memoryGateway.uploadMemory(
                albumId: albumServerId,
                title: memory.title,
                imageRemoteUrl: nil,
                fileData: imageData,
                fileName: MimeType.jpeg.fileName(for: memory.localIdUUID),
                mimeType: MimeType.jpeg.value
            )

            // Delete local image
            imageStorageRepository.delete(entity: .memory, localId: memory.localIdUUID)

            // Update local DB
            try await memoryRepository.markAsSynced(localId: memory.localIdUUID, serverId: Int(response.id))

            if let syncedMemory = Shared.MemoryMapper.shared.toDomain(response: response, localId: memory.localId, albumLocalId: memory.albumLocalId) {
                return .success(syncedMemory)
            }
            return .success(memory.with(serverId: .some(Int(response.id)), syncStatus: .synced))
        } catch {
            // Sync failed, enqueue for later
            syncQueueService.enqueue(entityType: .memory, operationType: .create, localId: memory.localIdUUID)
            return .successPendingSync(memory)
        }
    }
}
