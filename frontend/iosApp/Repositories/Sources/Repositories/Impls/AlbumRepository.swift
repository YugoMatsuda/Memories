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

    // MARK: - Server Sync (no event firing)

    public func syncSet(_ albums: [Album]) async throws {
        // Delete only synced items, preserve pending ones
        try await database.delete(
            where: #Predicate<LocalAlbum> { $0.syncStatusRaw == "synced" }
        )
        for album in albums {
            let targetLocalId = album.localId
            try await database.upsert(
                album,
                as: LocalAlbum.self,
                predicate: #Predicate { $0.localId == targetLocalId }
            )
        }
    }

    public func syncAppend(_ albums: [Album]) async throws {
        for album in albums {
            let targetLocalId = album.localId
            try await database.upsert(
                album,
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
        let targetLocalId = album.localId
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
        guard var album = await get(byLocalId: localId) else { return }
        album = album.with(id: serverId, syncStatus: .synced)
        try await update(album)
    }

    public func updateCoverImageUrl(localId: UUID, url: String) async throws {
        guard var album = await get(byLocalId: localId) else { return }
        album = album.with(coverImageUrl: URL(string: url))
        try await updateSilently(album)
    }

    // MARK: - Private

    private func updateSilently(_ album: Album) async throws {
        let targetLocalId = album.localId
        try await database.upsert(
            album,
            as: LocalAlbum.self,
            predicate: #Predicate { $0.localId == targetLocalId }
        )
    }
}
