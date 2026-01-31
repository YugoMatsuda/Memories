import Foundation
import Domains
import APIGateways
import Utilities

public enum AlbumMapper {
    public static func toDomain(_ response: AlbumResponse) -> Album {
        Album(
            id: response.id,
            title: response.title,
            coverImageUrl: response.coverImageUrl.flatMap { URL(string: $0) },
            createdAt: DateFormatters.iso8601.date(from: response.createdAt) ?? Date()
        )
    }
}
