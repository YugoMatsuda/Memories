import Foundation
import Combine
import SwiftData
import Domains

public final class SyncQueueRepository: SyncQueueRepositoryProtocol, @unchecked Sendable {
    private let database: SwiftDatabase
    private let stateSubject = CurrentValueSubject<SyncQueueState, Never>(SyncQueueState(pendingCount: 0, isSyncing: false))

    public var statePublisher: AnyPublisher<SyncQueueState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public init(database: SwiftDatabase) {
        self.database = database
    }

    public func enqueue(_ operation: SyncOperation) async throws {
        try await database.insert(operation, as: LocalSyncOperation.self)
        await refreshState()
    }

    public func peek() async -> [SyncOperation] {
        let descriptor = FetchDescriptor<LocalSyncOperation>(
            predicate: #Predicate { $0.statusRaw == "pending" || $0.statusRaw == "failed" },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        do {
            return try await database.fetch(descriptor)
        } catch {
            return []
        }
    }

    public func getAll() async -> [SyncOperation] {
        let descriptor = FetchDescriptor<LocalSyncOperation>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        do {
            return try await database.fetch(descriptor)
        } catch {
            return []
        }
    }

    public func remove(id: UUID) async throws {
        let targetId = id
        try await database.delete(
            where: #Predicate<LocalSyncOperation> { $0.id == targetId }
        )
        await refreshState()
    }

    public func updateStatus(id: UUID, status: SyncOperationStatus) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<LocalSyncOperation>(
            predicate: #Predicate { $0.id == targetId }
        )
        let operations = try await database.fetch(descriptor)
        guard var operation = operations.first else { return }
        operation.status = status
        try await database.upsert(
            operation,
            as: LocalSyncOperation.self,
            predicate: #Predicate { $0.id == targetId }
        )
        await refreshState()
    }

    public func setSyncing(_ isSyncing: Bool) {
        let current = stateSubject.value
        stateSubject.send(SyncQueueState(pendingCount: current.pendingCount, isSyncing: isSyncing))
    }

    public func refreshState() async {
        let pending = await peek()
        let current = stateSubject.value
        stateSubject.send(SyncQueueState(pendingCount: pending.count, isSyncing: current.isSyncing))
    }
}
