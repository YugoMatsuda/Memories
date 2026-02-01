import Foundation
import Domains
import APIGateways
import Utilities

public enum MemoryMapper {
    public static func toDomain(_ response: MemoryResponse) -> Memory? {
        let imageUrl: URL? = {
            if let uri = response.imageLocalUri {
                return URL(string: uri)
            }
            if let url = response.imageRemoteUrl {
                return URL(string: url)
            }
            return nil
        }()

        guard let imageUrl else { return nil }

        return Memory(
            id: response.id,
            albumId: response.albumId,
            title: response.title,
            imageUrl: imageUrl,
            createdAt: DateFormatters.iso8601.date(from: response.createdAt) ?? Date()
        )
    }
}
