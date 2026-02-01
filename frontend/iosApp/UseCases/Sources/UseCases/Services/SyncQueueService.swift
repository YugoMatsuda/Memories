import Foundation
import Domains
import Repositories
import APIGateways
import Utilities

public protocol SyncQueueServiceProtocol: Sendable {
    func enqueue(entityType: EntityType, operationType: OperationType, localId: UUID)
    func processQueue() async
}

public final class SyncQueueService: SyncQueueServiceProtocol, @unchecked Sendable {
    private let syncQueueRepository: SyncQueueRepositoryProtocol
    private let albumRepository: AlbumRepositoryProtocol
    private let memoryRepository: MemoryRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let albumGateway: AlbumGatewayProtocol
    private let memoryGateway: MemoryGatewayProtocol
    private let userGateway: UserGatewayProtocol
    private let imageStorageRepository: ImageStorageRepositoryProtocol
    private let reachabilityRepository: ReachabilityRepositoryProtocol

    public init(
        syncQueueRepository: SyncQueueRepositoryProtocol,
        albumRepository: AlbumRepositoryProtocol,
        memoryRepository: MemoryRepositoryProtocol,
        userRepository: UserRepositoryProtocol,
        albumGateway: AlbumGatewayProtocol,
        memoryGateway: MemoryGatewayProtocol,
        userGateway: UserGatewayProtocol,
        imageStorageRepository: ImageStorageRepositoryProtocol,
        reachabilityRepository: ReachabilityRepositoryProtocol
    ) {
        self.syncQueueRepository = syncQueueRepository
        self.albumRepository = albumRepository
        self.memoryRepository = memoryRepository
        self.userRepository = userRepository
        self.albumGateway = albumGateway
        self.memoryGateway = memoryGateway
        self.userGateway = userGateway
        self.imageStorageRepository = imageStorageRepository
        self.reachabilityRepository = reachabilityRepository
    }

    // MARK: - Public

    public func enqueue(entityType: EntityType, operationType: OperationType, localId: UUID) {
        let operation = SyncOperation(
            id: UUID(),
            entityType: entityType,
            operationType: operationType,
            localId: localId,
            createdAt: Date(),
            status: .pending
        )
        Task {
            do {
                try await syncQueueRepository.enqueue(operation)
            } catch {
                print("[SyncQueueService] Failed to enqueue sync operation: \(error)")
            }
        }
    }

    public func processQueue() async {
        guard reachabilityRepository.isConnected else { return }

        let operations = await syncQueueRepository.peek()

        for operation in operations {
            do {
                try await syncQueueRepository.updateStatus(id: operation.id, status: .inProgress)
            } catch {
                print("[SyncQueueService] Failed to update sync status to inProgress: \(error)")
            }

            do {
                try await execute(operation)
                do {
                    try await syncQueueRepository.remove(id: operation.id)
                } catch {
                    print("[SyncQueueService] Failed to remove completed sync operation: \(error)")
                }
            } catch {
                do {
                    try await syncQueueRepository.updateStatus(id: operation.id, status: .failed)
                } catch {
                    print("[SyncQueueService] Failed to update sync status to failed: \(error)")
                }
            }
        }
    }

    // MARK: - Private

    private func execute(_ operation: SyncOperation) async throws {
        switch operation.entityType {
        case .album:
            try await executeAlbum(operation)
        case .memory:
            try await executeMemory(operation)
        case .user:
            try await executeUser(operation)
        }
    }

    private func executeAlbum(_ operation: SyncOperation) async throws {
        switch operation.operationType {
        case .create:
            try await executeAlbumCreate(operation)
        case .update:
            try await executeAlbumUpdate(operation)
        }
    }

    private func executeMemory(_ operation: SyncOperation) async throws {
        switch operation.operationType {
        case .create:
            try await executeMemoryCreate(operation)
        case .update:
            print("[SyncQueueService] Memory update is not supported")
        }
    }

    private func executeUser(_ operation: SyncOperation) async throws {
        switch operation.operationType {
        case .create:
            print("[SyncQueueService] User create is not supported")
        case .update:
            try await executeUserUpdate(operation)
        }
    }

    private func executeAlbumCreate(_ operation: SyncOperation) async throws {
        guard var album = await albumRepository.get(byLocalId: operation.localId) else {
            return
        }

        // 1. Create album on server if not yet synced
        if album.id == nil {
            let response = try await albumGateway.createAlbum(title: album.title, coverImageUrl: nil)
            try await albumRepository.markAsSynced(localId: operation.localId, serverId: response.id)
            album = album.with(id: response.id, syncStatus: .synced)
        }

        // 2. Upload cover image if exists locally
        if album.coverImageLocalPath != nil, let serverId = album.id {
            let imageData = try imageStorageRepository.get(entity: .albumCover, localId: operation.localId)
            let response = try await albumGateway.uploadCoverImage(
                albumId: serverId,
                fileData: imageData,
                fileName: "\(operation.localId).jpg",
                mimeType: "image/jpeg"
            )
            if let coverUrl = response.coverImageUrl {
                try await albumRepository.updateCoverImageUrl(localId: operation.localId, url: coverUrl)
            }
            imageStorageRepository.delete(entity: .albumCover, localId: operation.localId)
        }
    }

    private func executeAlbumUpdate(_ operation: SyncOperation) async throws {
        guard let album = await albumRepository.get(byLocalId: operation.localId),
              let serverId = album.id else {
            return
        }

        // 1. Update album on server
        _ = try await albumGateway.updateAlbum(albumId: serverId, title: album.title, coverImageUrl: nil)

        // 2. Upload cover image if exists locally
        if album.coverImageLocalPath != nil {
            let imageData = try imageStorageRepository.get(entity: .albumCover, localId: operation.localId)
            let response = try await albumGateway.uploadCoverImage(
                albumId: serverId,
                fileData: imageData,
                fileName: "\(operation.localId).jpg",
                mimeType: "image/jpeg"
            )
            if let coverUrl = response.coverImageUrl {
                try await albumRepository.updateCoverImageUrl(localId: operation.localId, url: coverUrl)
            }
            imageStorageRepository.delete(entity: .albumCover, localId: operation.localId)
        }

        // 3. Mark as synced
        let updatedAlbum = album.with(syncStatus: .synced)
        try await albumRepository.update(updatedAlbum)
    }

    private func executeMemoryCreate(_ operation: SyncOperation) async throws {
        guard let memory = await memoryRepository.get(byLocalId: operation.localId) else {
            return
        }

        // Check if album is synced
        guard let albumServerId = memory.albumId else {
            // Album not synced yet, keep in queue
            throw SyncError.dependencyNotSynced
        }

        // Get local image data
        let imageData = try imageStorageRepository.get(entity: .memory, localId: operation.localId)

        // Upload to server
        let response = try await memoryGateway.uploadMemory(
            albumId: albumServerId,
            title: memory.title,
            imageRemoteUrl: nil,
            fileData: imageData,
            fileName: "\(operation.localId).jpg",
            mimeType: "image/jpeg"
        )

        // Delete local image
        imageStorageRepository.delete(entity: .memory, localId: operation.localId)

        // Update local DB
        try await memoryRepository.markAsSynced(localId: operation.localId, serverId: response.id)
    }

    private func executeUserUpdate(_ operation: SyncOperation) async throws {
        guard let user = await userRepository.get() else {
            return
        }

        // 1. Update profile on server
        let birthdayString = user.birthday.map { DateFormatters.yyyyMMdd.string(from: $0) }
        var response = try await userGateway.updateUser(
            name: user.name,
            birthday: birthdayString,
            avatarUrl: nil
        )

        // 2. Upload avatar if exists locally
        if user.avatarLocalPath != nil {
            let imageData = try imageStorageRepository.get(entity: .avatar, localId: operation.localId)
            response = try await userGateway.uploadAvatar(
                fileData: imageData,
                fileName: "\(operation.localId).jpg",
                mimeType: "image/jpeg"
            )
            imageStorageRepository.delete(entity: .avatar, localId: operation.localId)
        }

        // 3. Update local DB
        let syncedUser = UserMapper.toDomain(response)
        try await userRepository.set(syncedUser)
    }
}

// MARK: - SyncError

private enum SyncError: Error {
    case dependencyNotSynced
}
