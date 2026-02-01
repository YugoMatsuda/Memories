import Foundation
import Domains
import UseCases
import Utilities

@MainActor
public final class AlbumDetailViewModel: ObservableObject {
    @Published public private(set) var displayResult: DisplayResult = .loading

    public let album: Album
    private let albumDetailUseCase: AlbumDetailUseCaseProtocol
    private let router: AuthenticatedRouterProtocol

    private var isLoadingMore = false

    public init(album: Album, albumDetailUseCase: AlbumDetailUseCaseProtocol, router: AuthenticatedRouterProtocol) {
        self.album = album
        self.albumDetailUseCase = albumDetailUseCase
        self.router = router
    }

    public func onAppear() {
        guard case .loading = displayResult else { return }
        Task {
            await display()
        }
    }

    public func onLoadMore() {
        guard case .success(let listData) = displayResult,
              listData.hasMore,
              !isLoadingMore else { return }
        Task {
            await loadMore()
        }
    }

    public func showEditAlbumForm() {
        router.showSheet(.albumForm(.edit(album)))
    }

    public func showCreateMemoryForm() {
        router.showSheet(.memoryForm(albumId: album.id))
    }

    private func display() async {
        displayResult = .loading
        let result = await albumDetailUseCase.display(albumId: album.id)

        switch result {
        case .success(let pageInfo):
            displayResult = .success(makeListData(memories: pageInfo.memories, currentPage: 1, hasMore: pageInfo.hasMore))
        case .failure(let error):
            displayResult = .failure(mapDisplayError(error))
        }
    }

    private func loadMore() async {
        guard case .success(let currentData) = displayResult else { return }

        isLoadingMore = true
        let nextPage = currentData.currentPage + 1
        let result = await albumDetailUseCase.next(albumId: album.id, page: nextPage)
        isLoadingMore = false

        switch result {
        case .success(let pageInfo):
            let allMemories = currentData.memories + pageInfo.memories
            displayResult = .success(makeListData(memories: allMemories, currentPage: nextPage, hasMore: pageInfo.hasMore))
        case .failure:
            break
        }
    }

    private func makeListData(memories: [Memory], currentPage: Int, hasMore: Bool) -> ListData {
        let items = memories.map { memory in
            MemoryItemUIModel(
                id: memory.id,
                title: memory.title,
                imageUrl: memory.imageUrl,
                createdAt: memory.createdAt,
                didTap: {
                    // TODO: Navigate to memory detail
                }
            )
        }
        return ListData(memories: memories, items: items, currentPage: currentPage, hasMore: hasMore)
    }

    private func mapDisplayError(_ error: AlbumDetailUseCaseModel.DisplayResult.Error) -> ErrorUIModel {
        switch error {
        case .networkError:
            return ErrorUIModel(
                message: "Network error. Please check your connection.",
                retryAction: { [weak self] in
                    Task { await self?.display() }
                }
            )
        case .unknown:
            return ErrorUIModel(
                message: "An unexpected error occurred.",
                retryAction: { [weak self] in
                    Task { await self?.display() }
                }
            )
        }
    }
}

// MARK: - UI Models

extension AlbumDetailViewModel {
    public enum DisplayResult: Equatable {
        case loading
        case success(ListData)
        case failure(ErrorUIModel)
    }

    public struct ListData: Equatable {
        public let memories: [Memory]
        public let items: [MemoryItemUIModel]
        public let currentPage: Int
        public let hasMore: Bool

        public init(memories: [Memory], items: [MemoryItemUIModel], currentPage: Int, hasMore: Bool) {
            self.memories = memories
            self.items = items
            self.currentPage = currentPage
            self.hasMore = hasMore
        }
    }

    public struct MemoryItemUIModel: Equatable, Identifiable {
        public let id: Int
        public let title: String
        public let imageUrl: URL
        public let createdAt: Date
        @EquatableNoop public var didTap: @MainActor () -> Void

        public init(id: Int, title: String, imageUrl: URL, createdAt: Date, didTap: @escaping @MainActor () -> Void) {
            self.id = id
            self.title = title
            self.imageUrl = imageUrl
            self.createdAt = createdAt
            self.didTap = didTap
        }
    }

    public struct ErrorUIModel: Equatable {
        public let message: String
        @EquatableNoop public var retryAction: @MainActor () -> Void

        public init(message: String, retryAction: @escaping @MainActor () -> Void) {
            self.message = message
            self.retryAction = retryAction
        }
    }
}
