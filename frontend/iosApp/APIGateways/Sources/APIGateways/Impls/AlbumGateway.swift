import Foundation
import Domains
@preconcurrency import Shared

/// Adapter that wraps KMP AlbumGatewayImpl and exposes it through Swift protocol
public struct AlbumGatewayAdapter: AlbumGatewayProtocol, @unchecked Sendable {
    private let kmpGateway: Shared.AlbumGatewayImpl

    public init(kmpGateway: Shared.AlbumGatewayImpl) {
        self.kmpGateway = kmpGateway
    }

    public func getAlbum(id: Int) async throws -> Shared.AlbumResponse {
        try await kmpGateway.getAlbum(id: Int32(id))
    }

    public func getAlbums(page: Int, pageSize: Int) async throws -> Shared.PaginatedAlbumsResponse {
        try await kmpGateway.getAlbums(page: Int32(page), pageSize: Int32(pageSize))
    }

    public func createAlbum(title: String, coverImageUrl: String?) async throws -> Shared.AlbumResponse {
        try await kmpGateway.createAlbum(title: title, coverImageUrl: coverImageUrl)
    }

    public func updateAlbum(albumId: Int, title: String?, coverImageUrl: String?) async throws -> Shared.AlbumResponse {
        try await kmpGateway.updateAlbum(albumId: Int32(albumId), title: title, coverImageUrl: coverImageUrl)
    }

    public func uploadCoverImage(albumId: Int, fileData: Data, fileName: String, mimeType: String) async throws -> Shared.AlbumResponse {
        try await kmpGateway.uploadCoverImage(
            albumId: Int32(albumId),
            fileData: KotlinByteArray.from(data: fileData),
            fileName: fileName,
            mimeType: mimeType
        )
    }
}
