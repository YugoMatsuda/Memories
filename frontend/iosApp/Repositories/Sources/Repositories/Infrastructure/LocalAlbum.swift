import Foundation
import SwiftData
import Domains
import Shared

@Model
public final class LocalAlbum: DomainConvertible {
    public typealias Entity = Album

    @Attribute(.unique)
    public var localId: UUID

    public var serverId: Int?
    public var title: String
    public var coverImageUrl: String?
    public var coverImageLocalPath: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var syncStatusRaw: String

    // MARK: - DomainConvertible

    public required init(from entity: Album) {
        self.localId = entity.localId.uuid
        self.serverId = entity.serverId?.intValue
        self.title = entity.title
        self.coverImageUrl = entity.coverImageUrl
        self.coverImageLocalPath = entity.coverImageLocalPath
        self.createdAt = entity.createdAt.date
        self.updatedAt = Date()
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func update(from entity: Album) {
        self.serverId = entity.serverId?.intValue
        self.title = entity.title
        self.coverImageUrl = entity.coverImageUrl
        self.coverImageLocalPath = entity.coverImageLocalPath
        self.createdAt = entity.createdAt.date
        self.updatedAt = Date()
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func entity() -> Album {
        Album.create(
            serverId: serverId,
            localId: localId,
            title: title,
            coverImageUrl: coverImageUrl.flatMap { URL(string: $0) },
            coverImageLocalPath: coverImageLocalPath,
            createdAt: createdAt,
            syncStatus: Shared.__SyncStatus.from(rawValue: syncStatusRaw).toSwiftEnum()
        )
    }
}
