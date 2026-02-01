import Foundation

public struct User: Sendable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let name: String
    public let username: String
    public let birthday: Date?
    public let avatarUrl: URL?
    public let avatarLocalPath: String?
    public let syncStatus: SyncStatus

    public init(
        id: Int,
        name: String,
        username: String,
        birthday: Date?,
        avatarUrl: URL?,
        avatarLocalPath: String? = nil,
        syncStatus: SyncStatus = .synced
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.birthday = birthday
        self.avatarUrl = avatarUrl
        self.avatarLocalPath = avatarLocalPath
        self.syncStatus = syncStatus
    }

    // MARK: - Computed

    public var displayAvatar: URL? {
        if let remote = avatarUrl { return remote }
        if let local = avatarLocalPath { return URL(fileURLWithPath: local) }
        return nil
    }

    public var isSynced: Bool { syncStatus == .synced }

    // MARK: - Copy helpers

    public func with(
        name: String? = nil,
        birthday: Date?? = nil,
        avatarUrl: URL?? = nil,
        avatarLocalPath: String?? = nil,
        syncStatus: SyncStatus? = nil
    ) -> User {
        User(
            id: self.id,
            name: name ?? self.name,
            username: self.username,
            birthday: birthday ?? self.birthday,
            avatarUrl: avatarUrl ?? self.avatarUrl,
            avatarLocalPath: avatarLocalPath ?? self.avatarLocalPath,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}
