import Foundation
import Combine
import SwiftData
import Domains
import Shared

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
        // Get existing memories to preserve localIds
        let existingMemories = await getAll(albumLocalId: albumLocalId)
        let existingByServerId = Dictionary(uniqueKeysWithValues: existingMemories.compactMap { memory -> (Int, Memory)? in
            guard let serverId = memory.serverId?.intValue else { return nil }
            return (serverId, memory)
        })

        for memory in memories {
            // Preserve existing localId if memory exists (lookup by serverId)
            var memoryToSave = memory
            if let serverId = memory.serverId?.intValue, let existing = existingByServerId[serverId] {
                memoryToSave = Memory.create(
                    serverId: serverId,
                    localId: existing.localIdUUID,
                    albumId: memory.albumId?.intValue,
                    albumLocalId: memory.albumLocalId.uuid,
                    title: memory.title,
                    imageUrl: memory.imageURL,
                    imageLocalPath: memory.imageLocalPath,
                    createdAt: memory.createdAt.date,
                    syncStatus: memory.syncStatus
                )
            }

            // Upsert by localId
            let targetLocalId = memoryToSave.localId.uuid
            try await database.upsert(
                memoryToSave,
                as: LocalMemory.self,
                predicate: #Predicate { $0.localId == targetLocalId }
            )
        }
    }

    public func syncAppend(_ memories: [Memory]) async throws {
        // Get all existing memories to preserve localIds
        var existingByServerId: [Int: Memory] = [:]
        for memory in memories {
            if let serverId = memory.serverId?.intValue,
               let existing = await getByServerId(serverId) {
                existingByServerId[serverId] = existing
            }
        }

        for memory in memories {
            // Preserve existing localId if memory exists (lookup by serverId)
            var memoryToSave = memory
            if let serverId = memory.serverId?.intValue, let existing = existingByServerId[serverId] {
                memoryToSave = Memory.create(
                    serverId: serverId,
                    localId: existing.localIdUUID,
                    albumId: memory.albumId?.intValue,
                    albumLocalId: memory.albumLocalId.uuid,
                    title: memory.title,
                    imageUrl: memory.imageURL,
                    imageLocalPath: memory.imageLocalPath,
                    createdAt: memory.createdAt.date,
                    syncStatus: memory.syncStatus
                )
            }

            // Upsert by localId
            let targetLocalId = memoryToSave.localId.uuid
            try await database.upsert(
                memoryToSave,
                as: LocalMemory.self,
                predicate: #Predicate { $0.localId == targetLocalId }
            )
        }
    }

    private func getByServerId(_ serverId: Int) async -> Memory? {
        let targetServerId: Int? = serverId
        let descriptor = FetchDescriptor<LocalMemory>(
            predicate: #Predicate { $0.serverId == targetServerId }
        )
        do {
            return try await database.fetch(descriptor).first
        } catch {
            return nil
        }
    }

    // MARK: - Local Operations (fires events)

    public func insert(_ memory: Memory) async throws {
        try await database.insert(memory, as: LocalMemory.self)
        localChangeSubject.send(.created(memory))
    }

    // MARK: - Sync Status

    public func markAsSynced(localId: UUID, serverId: Int) async throws {
        guard let memory = await get(byLocalId: localId) else { return }
        let updatedMemory = memory.with(serverId: .some(serverId), syncStatus: .synced)
        let targetLocalId = updatedMemory.localId.uuid
        try await database.upsert(
            updatedMemory,
            as: LocalMemory.self,
            predicate: #Predicate { $0.localId == targetLocalId }
        )
    }
}
