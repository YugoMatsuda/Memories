import Foundation
import Combine
import SwiftData
import Domains

public final class SyncQueueRepository: SyncQueueRepositoryProtocol, @unchecked Sendable {
    private let database: SwiftDatabase
    private let stateSubject = CurrentValueSubject<SyncQueueState, Never>(SyncQueueState(pendingCount: 0, isSyncing: false))
    private let lock = NSLock()

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

    public func updateStatus(id: UUID, status: SyncOperationStatus, errorMessage: String?) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<LocalSyncOperation>(
            predicate: #Predicate { $0.id == targetId }
        )
        let operations: [SyncOperation] = try await database.fetch(descriptor)
        guard let operation = operations.first else { return }
        let updatedOperation = operation.with(status: status, errorMessage: .some(errorMessage))
        try await database.upsert(
            updatedOperation,
            as: LocalSyncOperation.self,
            predicate: #Predicate { $0.id == targetId }
        )
        await refreshState()
    }

    public func tryStartSyncing() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if stateSubject.value.isSyncing {
            return false
        }
        let current = stateSubject.value
        stateSubject.send(SyncQueueState(pendingCount: current.pendingCount, isSyncing: true))
        return true
    }

    public func stopSyncing() {
        lock.lock()
        defer { lock.unlock() }
        let current = stateSubject.value
        stateSubject.send(SyncQueueState(pendingCount: current.pendingCount, isSyncing: false))
    }

    public func refreshState() async {
        let pending = await peek()
        let current = stateSubject.value
        stateSubject.send(SyncQueueState(pendingCount: pending.count, isSyncing: current.isSyncing))
    }
}
