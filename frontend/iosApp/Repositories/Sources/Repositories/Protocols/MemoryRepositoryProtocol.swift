import Foundation
import Combine
import Domains

public enum LocalMemoryChangeEvent: Sendable {
    case created(Memory)
}

public protocol MemoryRepositoryProtocol: Sendable {
    // Read
    func getAll(albumLocalId: UUID) async -> [Memory]
    func get(byLocalId localId: UUID) async -> Memory?

    // Server Sync (no event firing)
    func syncSet(_ memories: [Memory], albumLocalId: UUID) async throws
    func syncAppend(_ memories: [Memory]) async throws

    // Local Operations (fires events)
    func insert(_ memory: Memory) async throws

    // Sync Status
    func markAsSynced(localId: UUID, serverId: Int) async throws

    // Change Publisher
    var localChangePublisher: AnyPublisher<LocalMemoryChangeEvent, Never> { get }
}
