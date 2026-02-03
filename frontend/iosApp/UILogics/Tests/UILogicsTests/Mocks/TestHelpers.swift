import Foundation
import Domains
@preconcurrency import Shared

enum TestHelpers {
    static func createUser(
        id: Int = 1,
        name: String = "Test User",
        username: String = "testuser",
        birthday: Date? = nil,
        avatarUrl: URL? = nil
    ) -> User {
        User.create(
            id: id,
            name: name,
            username: username,
            birthday: birthday,
            avatarUrl: avatarUrl,
            syncStatus: .synced
        )
    }

    static func createAlbum(
        serverId: Int? = 1,
        title: String = "Test Album"
    ) -> Album {
        Album.create(
            serverId: serverId,
            localId: UUID(),
            title: title,
            createdAt: Date(),
            syncStatus: .synced
        )
    }

    static func createMemory(
        serverId: Int? = 1,
        albumId: Int = 1,
        title: String = "Test Memory",
        albumLocalId: UUID = UUID()
    ) -> Memory {
        Memory.create(
            serverId: serverId,
            localId: UUID(),
            albumId: albumId,
            albumLocalId: albumLocalId,
            title: title,
            imageUrl: URL(string: "https://example.com/image.jpg"),
            createdAt: Date(),
            syncStatus: .synced
        )
    }

    static func createAuthSession(
        token: String = "test-token",
        userId: Int = 1
    ) -> AuthSession {
        Shared.AuthSession(token: token, userId: Int32(userId))
    }

    static func createAlbumPageInfo(
        albums: [Album] = [],
        hasMore: Bool = false
    ) -> Shared.AlbumPageInfo {
        Shared.AlbumPageInfo(albums: albums, hasMore: hasMore)
    }

    static func createMemoryPageInfo(
        memories: [Memory] = [],
        hasMore: Bool = false
    ) -> Shared.MemoryPageInfo {
        Shared.MemoryPageInfo(memories: memories, hasMore: hasMore)
    }
}
