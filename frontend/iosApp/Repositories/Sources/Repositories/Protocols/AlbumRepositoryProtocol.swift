import Foundation
import Combine
import Domains

public enum LocalAlbumChangeEvent: Sendable {
    case created(Album)
    case updated(Album)
}

public protocol AlbumRepositoryProtocol: Sendable {
    // Read
    func getAll() async -> [Album]
    func get(byLocalId localId: UUID) async -> Album?

    // Server Sync (no event firing)
    func syncSet(_ albums: [Album]) async throws
    func syncAppend(_ albums: [Album]) async throws

    // Local Operations (fires events)
    func insert(_ album: Album) async throws
    func update(_ album: Album) async throws
    func delete(byLocalId localId: UUID) async throws

    // Sync Status
    func markAsSynced(localId: UUID, serverId: Int) async throws
    func updateCoverImageUrl(localId: UUID, url: String) async throws

    // Change Publisher
    var localChangePublisher: AnyPublisher<LocalAlbumChangeEvent, Never> { get }
}
