import Foundation
import Domains
import APIGateways
import Utilities

public enum MemoryMapper {
    /// Map from server response (generates new localId)
    public static func toDomain(_ response: MemoryResponse, albumLocalId: UUID) -> Memory? {
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
            serverId: response.id,
            localId: UUID(),
            albumId: response.albumId,
            albumLocalId: albumLocalId,
            title: response.title,
            imageUrl: imageUrl,
            imageLocalPath: nil,
            createdAt: DateFormatters.iso8601.date(from: response.createdAt) ?? Date(),
            syncStatus: .synced
        )
    }

    /// Map from server response (preserves existing localId)
    public static func toDomain(_ response: MemoryResponse, localId: UUID, albumLocalId: UUID) -> Memory? {
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
            serverId: response.id,
            localId: localId,
            albumId: response.albumId,
            albumLocalId: albumLocalId,
            title: response.title,
            imageUrl: imageUrl,
            imageLocalPath: nil,
            createdAt: DateFormatters.iso8601.date(from: response.createdAt) ?? Date(),
            syncStatus: .synced
        )
    }
}
