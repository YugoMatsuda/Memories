import Foundation
import Shared
import Utilities

// Type alias for KMP Album
public typealias Album = Shared.Album

// MARK: - Swift-friendly extensions for KMP Album

extension Shared.Album {
    // MARK: - Identifiable conformance

    /// Server ID as optional Int (matching Swift conventions)
    public var id: Int? {
        serverId?.intValue
    }

    // MARK: - Swift Type Accessors

    /// LocalId as Swift UUID
    public var localIdUUID: UUID {
        localId.uuid
    }

    /// CreatedAt as Swift Date
    public var createdAtDate: Date {
        createdAt.date
    }

    /// Cover image URL as Swift URL
    public var coverImageURL: URL? {
        coverImageUrl?.url
    }

    /// Cover image local path as file URL
    public var coverImageLocalURL: URL? {
        coverImageLocalPath.map { URL(fileURLWithPath: $0) }
    }

    /// Display cover image as Swift URL (for UI)
    /// Resolves relative URLs using ImageURLResolver.baseURL
    public var displayCoverImageURL: URL? {
        if let remote = coverImageUrl { return ImageURLResolver.resolve(remote) }
        if let local = coverImageLocalPath { return ImageURLResolver.resolveLocalPath(local) }
        return nil
    }

    // MARK: - Convenience Initializer

    /// Create Album with Swift types
    public static func create(
        serverId: Int? = nil,
        localId: UUID,
        title: String,
        coverImageUrl: URL? = nil,
        coverImageLocalPath: String? = nil,
        createdAt: Date,
        syncStatus: Shared.SyncStatus
    ) -> Shared.Album {
        Shared.Album(
            serverId: serverId.map { KotlinInt(int: Int32($0)) },
            localId: Shared.LocalId.from(uuid: localId),
            title: title,
            coverImageUrl: coverImageUrl?.absoluteString,
            coverImageLocalPath: coverImageLocalPath,
            createdAt: Shared.Timestamp.from(date: createdAt),
            syncStatus: syncStatus
        )
    }

    // MARK: - Copy helpers (Swift-style)

    public func with(
        serverId: Int?? = nil,
        localId: UUID? = nil,
        title: String? = nil,
        coverImageUrl: URL?? = nil,
        coverImageLocalPath: String?? = nil,
        syncStatus: Shared.SyncStatus? = nil
    ) -> Shared.Album {
        // Handle double optional for nullable fields
        let newServerId: KotlinInt?
        if let serverIdOpt = serverId {
            newServerId = serverIdOpt.map { KotlinInt(int: Int32($0)) }
        } else {
            newServerId = self.serverId
        }

        let newCoverImageUrl: String?
        if let urlOpt = coverImageUrl {
            newCoverImageUrl = urlOpt?.absoluteString
        } else {
            newCoverImageUrl = self.coverImageUrl
        }

        let newCoverImageLocalPath: String?
        if let pathOpt = coverImageLocalPath {
            newCoverImageLocalPath = pathOpt
        } else {
            newCoverImageLocalPath = self.coverImageLocalPath
        }

        return Shared.Album(
            serverId: newServerId,
            localId: localId.map { Shared.LocalId.from(uuid: $0) } ?? self.localId,
            title: title ?? self.title,
            coverImageUrl: newCoverImageUrl,
            coverImageLocalPath: newCoverImageLocalPath,
            createdAt: self.createdAt,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}

// MARK: - Protocol Conformances
// Note: Hashable and Equatable are inherited from Kotlin/NSObject

extension Shared.Album: @retroactive Identifiable {}
