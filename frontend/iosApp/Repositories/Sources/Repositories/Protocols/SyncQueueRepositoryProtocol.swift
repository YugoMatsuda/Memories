import Foundation
import Domains

public protocol SyncQueueRepositoryProtocol: Sendable {
    func enqueue(_ operation: SyncOperation) async throws
    func peek() async -> [SyncOperation]
    func remove(id: UUID) async throws
    func updateStatus(id: UUID, status: SyncOperationStatus) async throws
}
