import Foundation
import Domains
import APIGateways

public final class AlbumDetailUseCase: AlbumDetailUseCaseProtocol, Sendable {
    private let memoryGateway: MemoryGatewayProtocol
    private let pageSize = 3

    public init(memoryGateway: MemoryGatewayProtocol) {
        self.memoryGateway = memoryGateway
    }

    public func display(albumId: Int) async -> AlbumDetailUseCaseModel.DisplayResult {
        do {
            print("AlbumDetailUseCase display")
            let response = try await memoryGateway.getMemories(albumId: albumId, page: 1, pageSize: pageSize)
            let memories = response.items.compactMap { MemoryMapper.toDomain($0) }
            let hasMore = response.page * response.pageSize < response.total
            return .success(AlbumDetailUseCaseModel.PageInfo(memories: memories, hasMore: hasMore))
        } catch {
            return .failure(mapError(error))
        }
    }

    public func next(albumId: Int, page: Int) async -> AlbumDetailUseCaseModel.NextResult {
        do {
            print("AlbumDetailUseCase Next", page)
            let response = try await memoryGateway.getMemories(albumId: albumId, page: page, pageSize: pageSize)
            let memories = response.items.compactMap { MemoryMapper.toDomain($0) }
            let hasMore = response.page * response.pageSize < response.total
            return .success(AlbumDetailUseCaseModel.PageInfo(memories: memories, hasMore: hasMore))
        } catch {
            return .failure(mapNextError(error))
        }
    }

    private func mapError(_ error: Error) -> AlbumDetailUseCaseModel.DisplayResult.Error {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }
        return .unknown
    }

    private func mapNextError(_ error: Error) -> AlbumDetailUseCaseModel.NextResult.Error {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }
        return .unknown
    }
}
