import Foundation
import SwiftData
import Domains

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
        self.localId = entity.localId
        self.serverId = entity.serverId
        self.albumId = entity.albumId
        self.albumLocalId = entity.albumLocalId
        self.title = entity.title
        self.imageUrl = entity.imageUrl?.absoluteString
        self.imageLocalPath = entity.imageLocalPath
        self.createdAt = entity.createdAt
        self.updatedAt = Date()
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func update(from entity: Memory) {
        self.serverId = entity.serverId
        self.albumId = entity.albumId
        self.title = entity.title
        self.imageUrl = entity.imageUrl?.absoluteString
        self.imageLocalPath = entity.imageLocalPath
        self.updatedAt = Date()
        self.syncStatusRaw = entity.syncStatus.rawValue
    }

    public func entity() -> Memory {
        Memory(
            serverId: serverId,
            localId: localId,
            albumId: albumId,
            albumLocalId: albumLocalId,
            title: title,
            imageUrl: imageUrl.flatMap { URL(string: $0) },
            imageLocalPath: imageLocalPath,
            createdAt: createdAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }
}
