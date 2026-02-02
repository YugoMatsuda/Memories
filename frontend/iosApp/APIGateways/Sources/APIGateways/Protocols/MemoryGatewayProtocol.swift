import Foundation
@preconcurrency import Shared

public protocol MemoryGatewayProtocol: Sendable {
    func getMemories(albumId: Int, page: Int, pageSize: Int) async throws -> Shared.PaginatedMemoriesResponse
    func uploadMemory(
        albumId: Int,
        title: String,
        imageRemoteUrl: String?,
        fileData: Data?,
        fileName: String?,
        mimeType: String?
    ) async throws -> Shared.MemoryResponse
}
