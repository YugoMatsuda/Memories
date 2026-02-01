import Foundation
import SwiftData
import Domains

@Model
public final class LocalUser: DomainConvertible {
    public typealias Entity = User

    @Attribute(.unique)
    public var userId: Int

    public var name: String
    public var username: String
    public var birthday: Date?
    public var avatarUrl: String?
    public var avatarLocalPath: String?
    public var syncStatusRaw: String

    // MARK: - DomainConvertible

    public required init(from entity: User) {
        self.userId = entity.id
        self.name = entity.name
        self.username = entity.username
        self.birthday = entity.birthday
        self.avatarUrl = entity.avatarUrl?.absoluteString
        self.avatarLocalPath = entity.avatarLocalPath
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func update(from entity: User) {
        self.name = entity.name
        self.username = entity.username
        self.birthday = entity.birthday
        self.avatarUrl = entity.avatarUrl?.absoluteString
        self.avatarLocalPath = entity.avatarLocalPath
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func entity() -> User {
        User(
            id: userId,
            name: name,
            username: username,
            birthday: birthday,
            avatarUrl: avatarUrl.flatMap { URL(string: $0) },
            avatarLocalPath: avatarLocalPath,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }
}
