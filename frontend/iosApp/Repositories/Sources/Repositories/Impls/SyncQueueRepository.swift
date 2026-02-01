import Foundation
import SwiftData
import Domains

public final class SyncQueueRepository: SyncQueueRepositoryProtocol, @unchecked Sendable {
    private let database: SwiftDatabase

    public init(database: SwiftDatabase) {
        self.database = database
    }

    public func enqueue(_ operation: SyncOperation) async throws {
        try await database.insert(operation, as: LocalSyncOperation.self)
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

    public func remove(id: UUID) async throws {
        let targetId = id
        try await database.delete(
            where: #Predicate<LocalSyncOperation> { $0.id == targetId }
        )
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
    }
}
