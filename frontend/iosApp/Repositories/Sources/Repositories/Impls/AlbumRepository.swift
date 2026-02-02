import Foundation
import Combine
import SwiftData
import Domains

public final class AlbumRepository: AlbumRepositoryProtocol, @unchecked Sendable {
    private let database: SwiftDatabase
    private let localChangeSubject = PassthroughSubject<LocalAlbumChangeEvent, Never>()

    public var localChangePublisher: AnyPublisher<LocalAlbumChangeEvent, Never> {
        localChangeSubject.eraseToAnyPublisher()
    }

    public init(database: SwiftDatabase) {
        self.database = database
    }

    // MARK: - Read

    public func getAll() async -> [Album] {
        let descriptor = FetchDescriptor<LocalAlbum>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try await database.fetch(descriptor)
        } catch {
            return []
        }
    }

    public func get(byLocalId localId: UUID) async -> Album? {
        let targetLocalId = localId
        let descriptor = FetchDescriptor<LocalAlbum>(
            predicate: #Predicate { $0.localId == targetLocalId }
        )
        do {
            return try await database.fetch(descriptor).first
        } catch {
            return nil
        }
    }

    public func get(byServerId serverId: Int) async -> Album? {
        let targetServerId: Int? = serverId
        let descriptor = FetchDescriptor<LocalAlbum>(
            predicate: #Predicate { $0.serverId == targetServerId }
        )
        do {
            return try await database.fetch(descriptor).first
        } catch {
            return nil
        }
    }

    // MARK: - Server Sync (no event firing)

    public func syncSet(_ albums: [Album]) async throws {
        // Get existing albums to preserve localIds
        let existingAlbums = await getAll()
        let existingByServerId = Dictionary(uniqueKeysWithValues: existingAlbums.compactMap { album -> (Int, Album)? in
            guard let serverId = album.id else { return nil }
            return (serverId, album)
        })

        for album in albums {
            // Preserve existing localId if album exists (lookup by serverId)
            var albumToSave = album
            if let serverId = album.id, let existing = existingByServerId[serverId] {
                albumToSave = album.with(localId: existing.localIdUUID)
            }

            // Upsert by localId
            let targetLocalId = albumToSave.localId.uuid
            try await database.upsert(
                albumToSave,
                as: LocalAlbum.self,
                predicate: #Predicate { $0.localId == targetLocalId }
            )
        }
    }

    public func syncAppend(_ albums: [Album]) async throws {
        // Get existing albums to preserve localIds
        let existingAlbums = await getAll()
        let existingByServerId = Dictionary(uniqueKeysWithValues: existingAlbums.compactMap { album -> (Int, Album)? in
            guard let serverId = album.id else { return nil }
            return (serverId, album)
        })

        for album in albums {
            // Preserve existing localId if album exists (lookup by serverId)
            var albumToSave = album
            if let serverId = album.id, let existing = existingByServerId[serverId] {
                albumToSave = album.with(localId: existing.localIdUUID)
            }

            // Upsert by localId
            let targetLocalId = albumToSave.localId.uuid
            try await database.upsert(
                albumToSave,
                as: LocalAlbum.self,
                predicate: #Predicate { $0.localId == targetLocalId }
            )
        }
    }

    // MARK: - Local Operations (fires events)

    public func insert(_ album: Album) async throws {
        try await database.insert(album, as: LocalAlbum.self)
        localChangeSubject.send(.created(album))
    }

    public func update(_ album: Album) async throws {
        let targetLocalId = album.localId.uuid
        try await database.upsert(
            album,
            as: LocalAlbum.self,
            predicate: #Predicate { $0.localId == targetLocalId }
        )
        localChangeSubject.send(.updated(album))
    }

    public func delete(byLocalId localId: UUID) async throws {
        let targetLocalId = localId
        try await database.delete(
            where: #Predicate<LocalAlbum> { $0.localId == targetLocalId }
        )
    }

    // MARK: - Sync Status

    public func markAsSynced(localId: UUID, serverId: Int) async throws {
        guard let album = await get(byLocalId: localId) else { return }
        let updatedAlbum = album.with(serverId: .some(serverId), syncStatus: .synced)
        try await update(updatedAlbum)
    }

    public func updateCoverImageUrl(localId: UUID, url: String) async throws {
        guard let album = await get(byLocalId: localId) else { return }
        let updatedAlbum = album.with(coverImageUrl: .some(URL(string: url)))
        try await updateSilently(updatedAlbum)
    }

    // MARK: - Private

    private func updateSilently(_ album: Album) async throws {
        let targetLocalId = album.localId.uuid
        try await database.upsert(
            album,
            as: LocalAlbum.self,
            predicate: #Predicate { $0.localId == targetLocalId }
        )
    }
}
