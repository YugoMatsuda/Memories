import Foundation
import Domains
import APIGateways
import Utilities

public enum AlbumMapper {
    public static func toDomain(_ response: AlbumResponse) -> Album {
        Album(
            id: response.id,
            localId: UUID(),
            title: response.title,
            coverImageUrl: response.coverImageUrl.flatMap { URL(string: $0) },
            coverImageLocalPath: nil,
            createdAt: DateFormatters.iso8601.date(from: response.createdAt) ?? Date(),
            syncStatus: .synced
        )
    }

    public static func toDomain(_ response: AlbumResponse, localId: UUID) -> Album {
        Album(
            id: response.id,
            localId: localId,
            title: response.title,
            coverImageUrl: response.coverImageUrl.flatMap { URL(string: $0) },
            coverImageLocalPath: nil,
            createdAt: DateFormatters.iso8601.date(from: response.createdAt) ?? Date(),
            syncStatus: .synced
        )
    }
}
