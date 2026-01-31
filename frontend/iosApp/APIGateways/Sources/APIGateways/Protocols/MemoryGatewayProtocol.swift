import Foundation
import APIClients

public protocol MemoryGatewayProtocol: Sendable {
    init(apiClient: any APIClientProtocol)
    func getMemories(albumId: Int, page: Int, pageSize: Int) async throws -> PaginatedMemoriesResponse
    func uploadMemory(
        albumId: Int,
        title: String,
        imageRemoteUrl: String?,
        fileData: Data?,
        fileName: String?,
        mimeType: String?
    ) async throws -> MemoryResponse
}
