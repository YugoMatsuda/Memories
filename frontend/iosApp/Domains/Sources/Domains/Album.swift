import Foundation

public struct Album: Sendable, Equatable, Hashable, Identifiable {
    // Identifiers
    public let id: Int?
    public let localId: UUID

    // Data
    public let title: String
    public let coverImageUrl: URL?
    public let coverImageLocalPath: String?
    public let createdAt: Date

    // Sync
    public let syncStatus: SyncStatus

    public init(
        id: Int?,
        localId: UUID,
        title: String,
        coverImageUrl: URL?,
        coverImageLocalPath: String?,
        createdAt: Date,
        syncStatus: SyncStatus
    ) {
        self.id = id
        self.localId = localId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.coverImageLocalPath = coverImageLocalPath
        self.createdAt = createdAt
        self.syncStatus = syncStatus
    }

    // MARK: - Computed

    public var isSynced: Bool { id != nil && syncStatus == .synced }

    public var displayCoverImage: URL? {
        if let remote = coverImageUrl { return remote }
        if let local = coverImageLocalPath { return URL(fileURLWithPath: local) }
        return nil
    }

    // MARK: - Copy helpers

    public func with(
        id: Int? = nil,
        localId: UUID? = nil,
        title: String? = nil,
        coverImageUrl: URL?? = nil,
        coverImageLocalPath: String?? = nil,
        syncStatus: SyncStatus? = nil
    ) -> Album {
        Album(
            id: id ?? self.id,
            localId: localId ?? self.localId,
            title: title ?? self.title,
            coverImageUrl: coverImageUrl ?? self.coverImageUrl,
            coverImageLocalPath: coverImageLocalPath ?? self.coverImageLocalPath,
            createdAt: self.createdAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}
