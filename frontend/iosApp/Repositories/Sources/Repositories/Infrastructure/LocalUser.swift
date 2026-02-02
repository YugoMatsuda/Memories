import Foundation
import SwiftData
import Domains
import Shared

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
        self.userId = Int(entity.id)
        self.name = entity.name
        self.username = entity.username
        self.birthday = entity.birthday?.date
        self.avatarUrl = entity.avatarUrl
        self.avatarLocalPath = entity.avatarLocalPath
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func update(from entity: User) {
        self.name = entity.name
        self.username = entity.username
        self.birthday = entity.birthday?.date
        self.avatarUrl = entity.avatarUrl
        self.avatarLocalPath = entity.avatarLocalPath
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func entity() -> User {
        User.create(
            id: userId,
            name: name,
            username: username,
            birthday: birthday,
            avatarUrl: avatarUrl.flatMap { URL(string: $0) },
            avatarLocalPath: avatarLocalPath,
            syncStatus: Shared.__SyncStatus.from(rawValue: syncStatusRaw).toSwiftEnum()
        )
    }
}
