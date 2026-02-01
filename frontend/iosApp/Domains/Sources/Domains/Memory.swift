import Foundation

public struct Memory: Sendable, Equatable, Hashable, Identifiable {
    public var id: Int? { serverId }
    public let serverId: Int?
    public let localId: UUID
    public let albumId: Int?
    public let albumLocalId: UUID
    public let title: String
    public let imageUrl: URL?
    public let imageLocalPath: String?
    public let createdAt: Date
    public let syncStatus: SyncStatus

    public init(
        serverId: Int?,
        localId: UUID,
        albumId: Int?,
        albumLocalId: UUID,
        title: String,
        imageUrl: URL?,
        imageLocalPath: String?,
        createdAt: Date,
        syncStatus: SyncStatus = .synced
    ) {
        self.serverId = serverId
        self.localId = localId
        self.albumId = albumId
        self.albumLocalId = albumLocalId
        self.title = title
        self.imageUrl = imageUrl
        self.imageLocalPath = imageLocalPath
        self.createdAt = createdAt
        self.syncStatus = syncStatus
    }

    // MARK: - Computed

    public var displayImage: URL? {
        if let remote = imageUrl { return remote }
        if let local = imageLocalPath { return URL(fileURLWithPath: local) }
        return nil
    }

    public var isSynced: Bool { syncStatus == .synced }

    // MARK: - Copy helpers

    public func with(
        serverId: Int?? = nil,
        albumId: Int?? = nil,
        syncStatus: SyncStatus? = nil
    ) -> Memory {
        Memory(
            serverId: serverId ?? self.serverId,
            localId: self.localId,
            albumId: albumId ?? self.albumId,
            albumLocalId: self.albumLocalId,
            title: self.title,
            imageUrl: self.imageUrl,
            imageLocalPath: self.imageLocalPath,
            createdAt: self.createdAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}
