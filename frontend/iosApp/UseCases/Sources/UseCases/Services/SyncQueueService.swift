import Foundation
import Combine
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
        print("[SyncQueueService] processQueue")
        guard reachabilityRepository.isConnected else { return }
        guard syncQueueRepository.tryStartSyncing() else {
            print("[SyncQueueService] Already processing, skipping")
            return
        }
        defer { syncQueueRepository.stopSyncing() }

        let operations = await syncQueueRepository.peek()
        guard !operations.isEmpty else {
            print("[SyncQueueService] there are no pending task")
            return
        }

        for operation in operations {
            do {
                try await syncQueueRepository.updateStatus(id: operation.id, status: .inProgress, errorMessage: nil)
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
            } catch let syncError {
                let errorMessage = mapErrorMessage(syncError)
                print("[SyncQueueService] Sync failed: \(errorMessage)")
                do {
                    try await syncQueueRepository.updateStatus(id: operation.id, status: .failed, errorMessage: errorMessage)
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
            print("[SyncQueueService] Album not found for localId: \(operation.localId)")
            return
        }

        print("[SyncQueueService] executeAlbumCreate - localId: \(album.localId), serverId: \(String(describing: album.id))")

        // 1. Create album on server if not yet synced
        if album.id == nil {
            let response = try await albumGateway.createAlbum(title: album.title, coverImageUrl: nil)
            print("[SyncQueueService] Album created on server with id: \(response.id)")
            try await albumRepository.markAsSynced(localId: operation.localId, serverId: response.id)
            print("[SyncQueueService] Album marked as synced")
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
            print("[SyncQueueService] Memory not found: \(operation.localId)")
            throw SyncError.entityNotFound
        }

        print("[SyncQueueService] Memory albumId: \(String(describing: memory.albumId)), albumLocalId: \(memory.albumLocalId)")

        // Get album server ID (either from memory or by looking up album)
        let albumServerId: Int
        if let id = memory.albumId {
            albumServerId = id
        } else {
            // Album was created offline, look up by localId
            let album = await albumRepository.get(byLocalId: memory.albumLocalId)
            print("[SyncQueueService] Album lookup result: \(String(describing: album)), serverId: \(String(describing: album?.id))")
            guard let album = album, let id = album.id else {
                // Album not synced yet, keep in queue
                throw SyncError.dependencyNotSynced
            }
            albumServerId = id
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

    private func mapErrorMessage(_ error: Error) -> String {
        if let syncError = error as? SyncError {
            switch syncError {
            case .dependencyNotSynced:
                return "Album not synced yet"
            case .entityNotFound:
                return "Entity not found in local DB"
            case .imageNotFound:
                return "Image file not found"
            }
        }
        return error.localizedDescription
    }
}

// MARK: - SyncError

private enum SyncError: Error {
    case dependencyNotSynced
    case entityNotFound
    case imageNotFound
}
