import Foundation
import Domains
import Repositories
import APIGateways

public struct AlbumFormUseCase: AlbumFormUseCaseProtocol, Sendable {
    private let albumRepository: AlbumRepositoryProtocol
    private let albumGateway: AlbumGatewayProtocol
    private let syncQueueService: SyncQueueServiceProtocol
    private let reachabilityRepository: ReachabilityRepositoryProtocol
    private let imageStorageRepository: ImageStorageRepositoryProtocol

    public init(
        albumRepository: AlbumRepositoryProtocol,
        albumGateway: AlbumGatewayProtocol,
        syncQueueService: SyncQueueServiceProtocol,
        reachabilityRepository: ReachabilityRepositoryProtocol,
        imageStorageRepository: ImageStorageRepositoryProtocol
    ) {
        self.albumRepository = albumRepository
        self.albumGateway = albumGateway
        self.syncQueueService = syncQueueService
        self.reachabilityRepository = reachabilityRepository
        self.imageStorageRepository = imageStorageRepository
    }

    public func createAlbum(title: String, coverImageData: Data?) async -> AlbumFormUseCaseModel.CreateResult {
        let localId = UUID()

        // 1. Save cover image locally
        var localImagePath: String? = nil
        if let imageData = coverImageData {
            do {
                localImagePath = try imageStorageRepository.save(imageData, entity: .albumCover, localId: localId)
            } catch {
                return .failure(.imageStorageFailed)
            }
        }

        // 2. Save to local DB (Optimistic)
        let album = Album(
            id: nil,
            localId: localId,
            title: title,
            coverImageUrl: nil,
            coverImageLocalPath: localImagePath,
            createdAt: Date(),
            syncStatus: .pendingCreate
        )
        do {
            try await albumRepository.insert(album)
        } catch {
            return .failure(.databaseError)
        }

        // 3. If offline, enqueue and return
        guard reachabilityRepository.isConnected else {
            syncQueueService.enqueue(entityType: .album, operationType: .create, localId: album.localId)
            return .successPendingSync(album)
        }

        // 4. If online, sync immediately
        return await syncCreate(album: album, coverImageData: coverImageData)
    }

    public func updateAlbum(album: Album, title: String, coverImageData: Data?) async -> AlbumFormUseCaseModel.UpdateResult {
        let localId = album.localId

        // 1. Save cover image locally if provided
        var localImagePath: String? = album.coverImageLocalPath
        if let imageData = coverImageData {
            do {
                localImagePath = try imageStorageRepository.save(imageData, entity: .albumCover, localId: localId)
            } catch {
                return .failure(.imageStorageFailed)
            }
        }

        // 2. Update local DB (Optimistic)
        let updatedAlbum = Album(
            id: album.id,
            localId: localId,
            title: title,
            coverImageUrl: album.coverImageUrl,
            coverImageLocalPath: localImagePath,
            createdAt: album.createdAt,
            syncStatus: .pendingUpdate
        )
        do {
            try await albumRepository.update(updatedAlbum)
        } catch {
            return .failure(.databaseError)
        }

        // 3. If offline or not synced yet, enqueue and return
        guard reachabilityRepository.isConnected else {
            syncQueueService.enqueue(entityType: .album, operationType: .update, localId: localId)
            return .successPendingSync(updatedAlbum)
        }

        guard let serverId = album.id else {
            // Not synced yet, enqueue for later
            syncQueueService.enqueue(entityType: .album, operationType: .update, localId: localId)
            return .successPendingSync(updatedAlbum)
        }

        // 4. If online, sync immediately
        return await syncUpdate(album: updatedAlbum, serverId: serverId, coverImageData: coverImageData)
    }

    // MARK: - Private

    private func syncCreate(album: Album, coverImageData: Data?) async -> AlbumFormUseCaseModel.CreateResult {
        do {
            // API call
            var response = try await albumGateway.createAlbum(title: album.title, coverImageUrl: nil)

            // Upload cover image
            if let imageData = coverImageData {
                response = try await albumGateway.uploadCoverImage(
                    albumId: response.id,
                    fileData: imageData,
                    fileName: "\(album.localId).jpg",
                    mimeType: "image/jpeg"
                )
                // Delete local image
                imageStorageRepository.delete(entity: .albumCover, localId: album.localId)
            }

            // Update local DB
            try await albumRepository.markAsSynced(localId: album.localId, serverId: response.id)

            let syncedAlbum = AlbumMapper.toDomain(response, localId: album.localId)
            return .success(syncedAlbum)
        } catch {
            // Sync failed, enqueue for later
            do {
                try await albumRepository.update(album.with(syncStatus: .failed))
            } catch {
                print("[AlbumFormUseCase] Failed to update album status to failed: \(error)")
            }
            syncQueueService.enqueue(entityType: .album, operationType: .create, localId: album.localId)
            return .successPendingSync(album)
        }
    }

    private func syncUpdate(album: Album, serverId: Int, coverImageData: Data?) async -> AlbumFormUseCaseModel.UpdateResult {
        do {
            // API call
            var response = try await albumGateway.updateAlbum(albumId: serverId, title: album.title, coverImageUrl: nil)

            // Upload cover image
            if let imageData = coverImageData {
                response = try await albumGateway.uploadCoverImage(
                    albumId: serverId,
                    fileData: imageData,
                    fileName: "\(album.localId).jpg",
                    mimeType: "image/jpeg"
                )
                // Delete local image
                imageStorageRepository.delete(entity: .albumCover, localId: album.localId)
            }

            let syncedAlbum = AlbumMapper.toDomain(response, localId: album.localId)
            try await albumRepository.update(syncedAlbum)
            return .success(syncedAlbum)
        } catch {
            // Sync failed, enqueue for later
            do {
                try await albumRepository.update(album.with(syncStatus: .failed))
            } catch {
                print("[AlbumFormUseCase] Failed to update album status to failed: \(error)")
            }
            syncQueueService.enqueue(entityType: .album, operationType: .update, localId: album.localId)
            return .successPendingSync(album)
        }
    }
}
