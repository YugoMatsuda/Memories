import Foundation
import Combine
import Domains
@preconcurrency import Shared

/// Swift implementation of AlbumRepositoryBridge that wraps the Swift AlbumRepository
public final class AlbumRepositoryBridgeImpl: Shared.AlbumRepositoryBridge, @unchecked Sendable {
    private let repository: AlbumRepositoryProtocol
    private var callback: Shared.AlbumChangeCallback?
    private var cancellable: AnyCancellable?

    public init(repository: AlbumRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Read

    public func __getAll() async throws -> [Shared.Album] {
        await repository.getAll()
    }

    public func __getByLocalId(localId: Shared.LocalId) async throws -> Shared.Album? {
        await repository.get(byLocalId: localId.uuid)
    }

    public func __getByServerId(serverId: Int32) async throws -> Shared.Album? {
        await repository.get(byServerId: Int(serverId))
    }

    // MARK: - Server Sync

    public func __syncSet(albums: [Shared.Album]) async throws {
        try await repository.syncSet(albums)
    }

    public func __syncAppend(albums: [Shared.Album]) async throws {
        try await repository.syncAppend(albums)
    }

    // MARK: - Local Operations

    public func __insert(album: Shared.Album) async throws {
        try await repository.insert(album)
    }

    public func __update(album: Shared.Album) async throws {
        try await repository.update(album)
    }

    public func __delete(localId: Shared.LocalId) async throws {
        try await repository.delete(byLocalId: localId.uuid)
    }

    // MARK: - Sync Status

    public func __markAsSynced(localId: Shared.LocalId, serverId: Int32) async throws {
        try await repository.markAsSynced(localId: localId.uuid, serverId: Int(serverId))
    }

    public func __updateCoverImageUrl(localId: Shared.LocalId, url: String) async throws {
        try await repository.updateCoverImageUrl(localId: localId.uuid, url: url)
    }

    // MARK: - Change Callback

    public func registerChangeCallback(callback: Shared.AlbumChangeCallback) {
        self.callback = callback
        cancellable = repository.localChangePublisher
            .sink { [weak self] event in
                switch event {
                case .created(let album):
                    self?.callback?.onCreated(album: album)
                case .updated(let album):
                    self?.callback?.onUpdated(album: album)
                }
            }
    }

    public func unregisterChangeCallback() {
        cancellable?.cancel()
        cancellable = nil
        callback = nil
    }
}
