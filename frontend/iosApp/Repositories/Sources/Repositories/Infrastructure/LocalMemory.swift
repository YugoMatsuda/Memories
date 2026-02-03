import Foundation
import SwiftData
import Domains
import Shared

@Model
public final class LocalMemory: DomainConvertible {
    public typealias Entity = Memory

    @Attribute(.unique)
    public var localId: UUID

    public var serverId: Int?
    public var albumId: Int?
    public var albumLocalId: UUID
    public var title: String
    public var imageUrl: String?
    public var imageLocalPath: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var syncStatusRaw: String

    // MARK: - DomainConvertible

    public required init(from entity: Memory) {
        self.localId = entity.localId.uuid
        self.serverId = entity.serverId?.intValue
        self.albumId = entity.albumId?.intValue
        self.albumLocalId = entity.albumLocalId.uuid
        self.title = entity.title
        self.imageUrl = entity.imageUrl
        self.imageLocalPath = entity.imageLocalPath
        self.createdAt = entity.createdAt.date
        self.updatedAt = Date()
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func update(from entity: Memory) {
        self.serverId = entity.serverId?.intValue
        self.albumId = entity.albumId?.intValue
        self.albumLocalId = entity.albumLocalId.uuid
        self.title = entity.title
        self.imageUrl = entity.imageUrl
        self.imageLocalPath = entity.imageLocalPath
        self.createdAt = entity.createdAt.date
        self.updatedAt = Date()
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func entity() -> Memory {
        Memory.create(
            serverId: serverId,
            localId: localId,
            albumId: albumId,
            albumLocalId: albumLocalId,
            title: title,
            imageUrl: imageUrl.flatMap { URL(string: $0) },
            imageLocalPath: imageLocalPath,
            createdAt: createdAt,
            syncStatus: Shared.__SyncStatus.from(rawValue: syncStatusRaw).toSwiftEnum()
        )
    }
}
