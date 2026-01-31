import Foundation
import APIClients

public struct MemoryGateway: MemoryGatewayProtocol {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func getMemories(albumId: Int, page: Int, pageSize: Int) async throws -> PaginatedMemoriesResponse {
        let request = GetMemoriesRequest(albumId: albumId, page: page, pageSize: pageSize)
        let data = try await apiClient.send(request)
        return try JSONDecoder().decode(PaginatedMemoriesResponse.self, from: data)
    }

    public func uploadMemory(
        albumId: Int,
        title: String,
        imageRemoteUrl: String?,
        fileData: Data?,
        fileName: String?,
        mimeType: String?
    ) async throws -> MemoryResponse {
        let request = MemoryUploadRequest(
            albumId: albumId,
            title: title,
            imageRemoteUrl: imageRemoteUrl,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType
        )
        let data = try await apiClient.send(request)
        return try JSONDecoder().decode(MemoryResponse.self, from: data)
    }
}
