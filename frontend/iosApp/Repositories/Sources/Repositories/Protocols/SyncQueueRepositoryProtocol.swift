import Foundation
import Combine
import Domains

public struct SyncQueueState: Equatable, Sendable {
    public let pendingCount: Int
    public let isSyncing: Bool

    public init(pendingCount: Int, isSyncing: Bool) {
        self.pendingCount = pendingCount
        self.isSyncing = isSyncing
    }
}

public protocol SyncQueueRepositoryProtocol: Sendable {
    func enqueue(_ operation: SyncOperation) async throws
    func peek() async -> [SyncOperation]
    func getAll() async -> [SyncOperation]
    func remove(id: UUID) async throws
    func updateStatus(id: UUID, status: SyncOperationStatus) async throws
    func setSyncing(_ isSyncing: Bool)
    func refreshState() async
    var statePublisher: AnyPublisher<SyncQueueState, Never> { get }
}
