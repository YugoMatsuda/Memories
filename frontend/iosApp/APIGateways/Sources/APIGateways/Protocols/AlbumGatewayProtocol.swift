import Foundation
@preconcurrency import Shared

public protocol AlbumGatewayProtocol: Sendable {
    func getAlbum(id: Int) async throws -> Shared.AlbumResponse
    func getAlbums(page: Int, pageSize: Int) async throws -> Shared.PaginatedAlbumsResponse
    func createAlbum(title: String, coverImageUrl: String?) async throws -> Shared.AlbumResponse
    func updateAlbum(albumId: Int, title: String?, coverImageUrl: String?) async throws -> Shared.AlbumResponse
    func uploadCoverImage(albumId: Int, fileData: Data, fileName: String, mimeType: String) async throws -> Shared.AlbumResponse
}
