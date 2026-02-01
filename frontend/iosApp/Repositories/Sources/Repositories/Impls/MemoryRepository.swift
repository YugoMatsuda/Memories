import Foundation
import Combine
import SwiftData
import Domains

public final class MemoryRepository: MemoryRepositoryProtocol, @unchecked Sendable {
    private let database: SwiftDatabase
    private let localChangeSubject = PassthroughSubject<LocalMemoryChangeEvent, Never>()

    public var localChangePublisher: AnyPublisher<LocalMemoryChangeEvent, Never> {
        localChangeSubject.eraseToAnyPublisher()
    }

    public init(database: SwiftDatabase) {
        self.database = database
    }

    // MARK: - Read

    public func getAll(albumLocalId: UUID) async -> [Memory] {
        let targetAlbumLocalId = albumLocalId
        let descriptor = FetchDescriptor<LocalMemory>(
            predicate: #Predicate { $0.albumLocalId == targetAlbumLocalId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try await database.fetch(descriptor)
        } catch {
            return []
        }
    }

    public func get(byLocalId localId: UUID) async -> Memory? {
        let targetLocalId = localId
        let descriptor = FetchDescriptor<LocalMemory>(
            predicate: #Predicate { $0.localId == targetLocalId }
        )
        do {
            return try await database.fetch(descriptor).first
        } catch {
            return nil
        }
    }

    // MARK: - Server Sync (no event firing)

    public func syncSet(_ memories: [Memory], albumLocalId: UUID) async throws {
        let targetAlbumLocalId = albumLocalId
        // Delete only synced items for this album, preserve pending ones
        try await database.delete(
            where: #Predicate<LocalMemory> {
                $0.albumLocalId == targetAlbumLocalId && $0.syncStatusRaw == "synced"
            }
        )
        for memory in memories {
            let targetLocalId = memory.localId
            try await database.upsert(
                memory,
                as: LocalMemory.self,
                predicate: #Predicate { $0.localId == targetLocalId }
            )
        }
    }

    public func syncAppend(_ memories: [Memory]) async throws {
        for memory in memories {
            let targetLocalId = memory.localId
            try await database.upsert(
                memory,
                as: LocalMemory.self,
                predicate: #Predicate { $0.localId == targetLocalId }
            )
        }
    }

    // MARK: - Local Operations (fires events)

    public func insert(_ memory: Memory) async throws {
        try await database.insert(memory, as: LocalMemory.self)
        localChangeSubject.send(.created(memory))
    }

    // MARK: - Sync Status

    public func markAsSynced(localId: UUID, serverId: Int) async throws {
        guard var memory = await get(byLocalId: localId) else { return }
        memory = memory.with(serverId: serverId, syncStatus: .synced)
        let targetLocalId = memory.localId
        try await database.upsert(
            memory,
            as: LocalMemory.self,
            predicate: #Predicate { $0.localId == targetLocalId }
        )
    }
}
