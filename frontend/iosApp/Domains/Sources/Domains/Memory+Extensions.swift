import Foundation
import Shared

// Type alias for KMP Memory
public typealias Memory = Shared.Memory

// MARK: - Swift-friendly extensions for KMP Memory

extension Shared.Memory {
    // MARK: - Identifiable conformance

    /// Server ID as optional Int
    public var id: Int? {
        serverId?.intValue
    }

    // MARK: - Swift Type Accessors

    /// LocalId as Swift UUID
    public var localIdUUID: UUID {
        localId.uuid
    }

    /// Album ID as optional Int
    public var albumIdInt: Int? {
        albumId?.intValue
    }

    /// Album LocalId as Swift UUID
    public var albumLocalIdUUID: UUID {
        albumLocalId.uuid
    }

    /// CreatedAt as Swift Date
    public var createdAtDate: Date {
        createdAt.date
    }

    /// Image URL as Swift URL
    public var imageURL: URL? {
        imageUrl?.url
    }

    /// Image local path as file URL
    public var imageLocalURL: URL? {
        imageLocalPath.map { URL(fileURLWithPath: $0) }
    }

    /// Display image as Swift URL (for UI)
    public var displayImageURL: URL? {
        if let remote = imageUrl { return URL(string: remote) }
        if let local = imageLocalPath { return URL(fileURLWithPath: local) }
        return nil
    }

    // MARK: - Convenience Initializer

    /// Create Memory with Swift types
    public static func create(
        serverId: Int? = nil,
        localId: UUID,
        albumId: Int? = nil,
        albumLocalId: UUID,
        title: String,
        imageUrl: URL? = nil,
        imageLocalPath: String? = nil,
        createdAt: Date,
        syncStatus: Shared.SyncStatus = .synced
    ) -> Shared.Memory {
        Shared.Memory(
            serverId: serverId.map { KotlinInt(int: Int32($0)) },
            localId: Shared.LocalId.from(uuid: localId),
            albumId: albumId.map { KotlinInt(int: Int32($0)) },
            albumLocalId: Shared.LocalId.from(uuid: albumLocalId),
            title: title,
            imageUrl: imageUrl?.absoluteString,
            imageLocalPath: imageLocalPath,
            createdAt: Shared.Timestamp.from(date: createdAt),
            syncStatus: syncStatus
        )
    }

    // MARK: - Copy helpers (Swift-style)

    public func with(
        serverId: Int?? = nil,
        albumId: Int?? = nil,
        syncStatus: Shared.SyncStatus? = nil
    ) -> Shared.Memory {
        let newServerId: KotlinInt?
        if let serverIdOpt = serverId {
            newServerId = serverIdOpt.map { KotlinInt(int: Int32($0)) }
        } else {
            newServerId = self.serverId
        }

        let newAlbumId: KotlinInt?
        if let albumIdOpt = albumId {
            newAlbumId = albumIdOpt.map { KotlinInt(int: Int32($0)) }
        } else {
            newAlbumId = self.albumId
        }

        return Shared.Memory(
            serverId: newServerId,
            localId: self.localId,
            albumId: newAlbumId,
            albumLocalId: self.albumLocalId,
            title: self.title,
            imageUrl: self.imageUrl,
            imageLocalPath: self.imageLocalPath,
            createdAt: self.createdAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}

// MARK: - Protocol Conformances
// Note: Hashable and Equatable are inherited from Kotlin/NSObject

extension Shared.Memory: @retroactive Identifiable {}
