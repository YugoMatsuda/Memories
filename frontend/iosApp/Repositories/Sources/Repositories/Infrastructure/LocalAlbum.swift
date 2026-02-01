import Foundation
import SwiftData
import Domains

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
        self.localId = entity.localId
        self.serverId = entity.id
        self.title = entity.title
        self.coverImageUrl = entity.coverImageUrl?.absoluteString
        self.coverImageLocalPath = entity.coverImageLocalPath
        self.createdAt = entity.createdAt
        self.updatedAt = Date()
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func update(from entity: Album) {
        self.serverId = entity.id
        self.title = entity.title
        self.coverImageUrl = entity.coverImageUrl?.absoluteString
        self.coverImageLocalPath = entity.coverImageLocalPath
        self.updatedAt = Date()
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func entity() -> Album {
        Album(
            id: serverId,
            localId: localId,
            title: title,
            coverImageUrl: coverImageUrl.flatMap { URL(string: $0) },
            coverImageLocalPath: coverImageLocalPath,
            createdAt: createdAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }
}
