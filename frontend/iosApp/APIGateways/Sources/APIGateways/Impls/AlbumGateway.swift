import Foundation
import APIClients

public struct AlbumGateway: AlbumGatewayProtocol {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func getAlbums(page: Int, pageSize: Int) async throws -> PaginatedAlbumsResponse {
        let request = GetAlbumsRequest(page: page, pageSize: pageSize)
        let data = try await apiClient.send(request)
        return try JSONDecoder().decode(PaginatedAlbumsResponse.self, from: data)
    }

    public func createAlbum(title: String, coverImageUrl: String?) async throws -> AlbumResponse {
        let request = AlbumCreateRequest(title: title, coverImageUrl: coverImageUrl)
        let data = try await apiClient.send(request)
        return try JSONDecoder().decode(AlbumResponse.self, from: data)
    }

    public func updateAlbum(albumId: Int, title: String?, coverImageUrl: String?) async throws -> AlbumResponse {
        let request = AlbumUpdateRequest(albumId: albumId, title: title, coverImageUrl: coverImageUrl)
        let data = try await apiClient.send(request)
        return try JSONDecoder().decode(AlbumResponse.self, from: data)
    }

    public func uploadCoverImage(albumId: Int, fileData: Data, fileName: String, mimeType: String) async throws -> AlbumResponse {
        let request = AlbumCoverUploadRequest(albumId: albumId, fileData: fileData, fileName: fileName, mimeType: mimeType)
        let data = try await apiClient.send(request)
        return try JSONDecoder().decode(AlbumResponse.self, from: data)
    }
}
