import Foundation
import Combine
import Domains

public protocol SyncQueuesUseCaseProtocol: Sendable {
    func observeState() -> AnyPublisher<Void, Never>
    func getAll() async -> [SyncQueueItem]
}

// MARK: - SyncQueueItem

public struct SyncQueueItem: Sendable {
    public let operation: SyncOperation
    public let entityTitle: String?
    public let entityServerId: Int?

    public init(
        operation: SyncOperation,
        entityTitle: String?,
        entityServerId: Int?
    ) {
        self.operation = operation
        self.entityTitle = entityTitle
        self.entityServerId = entityServerId
    }
}
