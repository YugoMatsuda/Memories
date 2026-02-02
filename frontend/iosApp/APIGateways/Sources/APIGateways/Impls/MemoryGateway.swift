import Foundation
import Domains
@preconcurrency import Shared

/// Adapter that wraps KMP MemoryGatewayImpl and exposes it through Swift protocol
public struct MemoryGatewayAdapter: MemoryGatewayProtocol, @unchecked Sendable {
    private let kmpGateway: Shared.MemoryGatewayImpl

    public init(kmpGateway: Shared.MemoryGatewayImpl) {
        self.kmpGateway = kmpGateway
    }

    public func getMemories(albumId: Int, page: Int, pageSize: Int) async throws -> Shared.PaginatedMemoriesResponse {
        try await kmpGateway.getMemories(albumId: Int32(albumId), page: Int32(page), pageSize: Int32(pageSize))
    }

    public func uploadMemory(
        albumId: Int,
        title: String,
        imageRemoteUrl: String?,
        fileData: Data?,
        fileName: String?,
        mimeType: String?
    ) async throws -> Shared.MemoryResponse {
        try await kmpGateway.uploadMemory(
            albumId: Int32(albumId),
            title: title,
            imageRemoteUrl: imageRemoteUrl,
            fileData: fileData.map { KotlinByteArray.from(data: $0) },
            fileName: fileName,
            mimeType: mimeType
        )
    }
}
