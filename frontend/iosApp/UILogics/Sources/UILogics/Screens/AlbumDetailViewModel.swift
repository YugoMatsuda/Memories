import Foundation
import Combine
import Domains
import Repositories
import UseCases
import Utilities

@MainActor
public final class AlbumDetailViewModel: ObservableObject {
    @Published public private(set) var displayResult: DisplayResult = .loading
    @Published public private(set) var album: Album?

    // Viewer state (nil = hidden, non-nil = showing)
    @Published public var viewerMemoryId: UUID?

    private let origin: AlbumDetailOrigin
    private let albumDetailUseCase: AlbumDetailUseCaseProtocol
    private let router: AuthenticatedRouterProtocol
    private var cancellables = Set<AnyCancellable>()

    private var isLoadingMore = false

    public init(origin: AlbumDetailOrigin, albumDetailUseCase: AlbumDetailUseCaseProtocol, router: AuthenticatedRouterProtocol) {
        self.origin = origin
        self.albumDetailUseCase = albumDetailUseCase
        self.router = router

        switch origin {
        case .albumList(let album):
            self.album = album
        case .deepLink:
            self.album = nil
        }

        albumDetailUseCase.localChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleLocalChange(event)
            }
            .store(in: &cancellables)

        albumDetailUseCase.observeAlbumUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleAlbumChange(event)
            }
            .store(in: &cancellables)
    }

    public func onAppear() {
        guard case .loading = displayResult else { return }
        Task {
            switch origin {
            case .albumList:
                await display()
            case .deepLink(let serverId):
                await resolveAlbumAndDisplay(serverId: serverId)
            }
        }
    }

    private func resolveAlbumAndDisplay(serverId: Int) async {
        displayResult = .loading

        let result = await albumDetailUseCase.resolveAlbum(serverId: serverId)

        switch result {
        case .success(let album):
            self.album = album
            await display()

        case .failure(let error):
            displayResult = .failure(mapResolveError(error))
        }
    }

    private func mapResolveError(_ error: AlbumDetailUseCaseModel.ResolveAlbumResult.Error) -> ErrorUIModel {
        switch error {
        case .notFound:
            return ErrorUIModel(
                message: "Album not found.",
                retryAction: { }
            )
        case .networkError:
            return ErrorUIModel(
                message: "Network error. Please check your connection.",
                retryAction: { [weak self] in
                    guard case .deepLink(let serverId) = self?.origin else { return }
                    Task { await self?.resolveAlbumAndDisplay(serverId: serverId) }
                }
            )
        case .offlineUnavailable:
            return ErrorUIModel(
                message: "This album is not available offline.",
                retryAction: { [weak self] in
                    guard case .deepLink(let serverId) = self?.origin else { return }
                    Task { await self?.resolveAlbumAndDisplay(serverId: serverId) }
                }
            )
        }
    }

    public func onLoadMore() {
        guard case .success(let listData) = displayResult,
              listData.hasMore,
              !isLoadingMore else { return }
        isLoadingMore = true
        Task {
            await loadMore()
        }
    }

    public func showEditAlbumForm() {
        guard let album else { return }
        router.showSheet(.albumForm(.edit(album)))
    }

    public func showCreateMemoryForm() {
        guard let album else { return }
        router.showSheet(.memoryForm(album: album))
    }

    private func display() async {
        guard let album else { return }
        displayResult = .loading
        let result = await albumDetailUseCase.display(album: album)

        switch result {
        case .success(let pageInfo):
            displayResult = .success(makeListData(memories: pageInfo.memories, currentPage: 1, hasMore: pageInfo.hasMore))
        case .failure(let error):
            displayResult = .failure(mapDisplayError(error))
        }
    }

    private func loadMore() async {
        guard let album, case .success(let currentData) = displayResult else { return }

        let previousCount = currentData.memories.count
        let nextPage = currentData.currentPage + 1
        let result = await albumDetailUseCase.next(album: album, page: nextPage)

        switch result {
        case .success(let pageInfo):
            displayResult = .success(makeListData(memories: pageInfo.memories, currentPage: nextPage, hasMore: pageInfo.hasMore))

            // If data didn't increase but hasMore is true, fetch next page automatically
            if pageInfo.memories.count == previousCount && pageInfo.hasMore {
                await loadMore()
            } else {
                isLoadingMore = false
            }
        case .failure:
            isLoadingMore = false
        }
    }

    private func handleLocalChange(_ event: Repositories.LocalMemoryChangeEvent) {
        guard let album, case .success(let currentData) = displayResult else { return }

        switch event {
        case .created(let memory):
            guard memory.albumLocalId == album.localId else { return }
            var memories = currentData.memories
            memories.insert(memory, at: 0)
            displayResult = .success(makeListData(memories: memories, currentPage: currentData.currentPage, hasMore: currentData.hasMore))
        }
    }

    private func handleAlbumChange(_ event: Repositories.LocalAlbumChangeEvent) {
        switch event {
        case .created:
            break
        case .updated(let updatedAlbum):
            guard let album, updatedAlbum.localId == album.localId else { return }
            self.album = updatedAlbum
        }
    }

    private func makeListData(memories: [Memory], currentPage: Int, hasMore: Bool) -> ListData {
        let items = memories.map { memory in
            MemoryItemUIModel(
                id: memory.localIdUUID,
                title: memory.title,
                displayImage: memory.displayImageURL,
                createdAt: memory.createdAtDate,
                syncStatus: memory.syncStatus,
                didTap: { [weak self] in
                    self?.showMemoryViewer(memoryId: memory.localIdUUID)
                }
            )
        }
        return ListData(memories: memories, items: items, currentPage: currentPage, hasMore: hasMore)
    }

    public func showMemoryViewer(memoryId: UUID) {
        viewerMemoryId = memoryId
    }

    public func closeMemoryViewer() {
        viewerMemoryId = nil
    }

    private func mapDisplayError(_ error: AlbumDetailUseCaseModel.DisplayResult.Error) -> ErrorUIModel {
        switch error {
        case .offline:
            return ErrorUIModel(
                message: "You are offline. No cached memories available.",
                retryAction: { [weak self] in
                    Task { await self?.display() }
                }
            )
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
        public let id: UUID
        public let title: String
        public let displayImage: URL?
        public let createdAt: Date
        public let syncStatus: SyncStatus
        @EquatableNoop public var didTap: @MainActor () -> Void

        public init(id: UUID, title: String, displayImage: URL?, createdAt: Date, syncStatus: SyncStatus, didTap: @escaping @MainActor () -> Void) {
            self.id = id
            self.title = title
            self.displayImage = displayImage
            self.createdAt = createdAt
            self.syncStatus = syncStatus
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
