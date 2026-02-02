import Foundation
import APIClients

public protocol AlbumGatewayProtocol: Sendable {
    init(apiClient: any APIClientProtocol)
    func getAlbum(id: Int) async throws -> AlbumResponse
    func getAlbums(page: Int, pageSize: Int) async throws -> PaginatedAlbumsResponse
    func createAlbum(title: String, coverImageUrl: String?) async throws -> AlbumResponse
    func updateAlbum(albumId: Int, title: String?, coverImageUrl: String?) async throws -> AlbumResponse
    func uploadCoverImage(albumId: Int, fileData: Data, fileName: String, mimeType: String) async throws -> AlbumResponse
}
