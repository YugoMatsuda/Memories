import Foundation
import Combine
import Domains
import Repositories
import UseCases
import Utilities

@MainActor
public final class AlbumListViewModel: ObservableObject {
    @Published public private(set) var userIcon: UserIconUIModel?
    @Published public private(set) var displayResult: DisplayResult = .loading
    @Published public private(set) var syncState: SyncQueueState = SyncQueueState(pendingCount: 0, isSyncing: false)
    @Published public private(set) var isOnline: Bool = true

    public let isNetworkDebugMode: Bool

    private let albumListUseCase: AlbumListUseCaseProtocol
    private let router: AuthenticatedRouterProtocol
    private var cancellables = Set<AnyCancellable>()

    private var isLoadingMore = false

    public init(
        albumListUseCase: AlbumListUseCaseProtocol,
        router: AuthenticatedRouterProtocol,
        isNetworkDebugMode: Bool
    ) {
        self.albumListUseCase = albumListUseCase
        self.router = router
        self.isNetworkDebugMode = isNetworkDebugMode

        albumListUseCase.observeUser()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                self.userIcon = UserIconUIModel(
                    avatarUrl: user.displayAvatar,
                    didTap: { [weak self] in
                        self?.router.push(.userProfile(user))
                    }
                )
            }
            .store(in: &cancellables)

        albumListUseCase.observeAlbumChange()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleLocalChange(event)
            }
            .store(in: &cancellables)

        albumListUseCase.observeSync()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.syncState = state
            }
            .store(in: &cancellables)

        albumListUseCase.observeOnlineState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isOnline in
                self?.isOnline = isOnline
            }
            .store(in: &cancellables)
    }

    public func toggleOnlineState() {
        albumListUseCase.toggleOnlineState()
    }

    private func handleLocalChange(_ event: LocalAlbumChangeEvent) {
        guard case .success(let currentData) = displayResult else { return }

        var albums = currentData.albums

        switch event {
        case .created(let album):
            albums.insert(album, at: 0)
        case .updated(let album):
            if let index = albums.firstIndex(where: { $0.localId == album.localId }) {
                albums[index] = album
            }
        }

        displayResult = .success(makeListData(albums: albums, currentPage: currentData.currentPage, hasMore: currentData.hasMore))
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
        isLoadingMore = true
        Task {
            await loadMore()
        }
    }

    public func showCreateAlbumForm() {
        router.showSheet(.albumForm(.create))
    }

    public func showEditAlbumForm(album: Album) {
        router.showSheet(.albumForm(.edit(album)))
    }

    public func showSyncQueues() {
        router.push(.syncQueues)
    }

    private func display() async {
        displayResult = .loading
        let result = await albumListUseCase.display()

        switch result {
        case .success(let pageInfo):
            displayResult = .success(makeListData(albums: pageInfo.albums, currentPage: 1, hasMore: pageInfo.hasMore))
        case .failure(let error):
            displayResult = .failure(mapDisplayError(error))
        }
    }

    private func loadMore() async {
        guard case .success(let currentData) = displayResult else { return }

        let nextPage = currentData.currentPage + 1
        let result = await albumListUseCase.next(page: nextPage)
        isLoadingMore = false

        switch result {
        case .success(let pageInfo):
            // pageInfo.albums already contains all albums from repository
            displayResult = .success(makeListData(albums: pageInfo.albums, currentPage: nextPage, hasMore: pageInfo.hasMore))
        case .failure:
            break
        }
    }

    private func makeListData(albums: [Album], currentPage: Int, hasMore: Bool) -> ListData {
        let items = albums.map { album in
            AlbumItemUIModel(
                id: album.localId,
                title: album.title,
                coverImageUrl: album.displayCoverImage,
                syncStatus: album.syncStatus,
                didTap: { [weak self] in
                    self?.router.push(.albumDetail(album))
                }
            )
        }
        return ListData(albums: albums, items: items, currentPage: currentPage, hasMore: hasMore)
    }

    private func mapDisplayError(_ error: AlbumListUseCaseModel.DisplayResult.Error) -> ErrorUIModel {
        switch error {
        case .networkError:
            return ErrorUIModel(
                message: "Network error. Please check your connection.",
                retryAction: { [weak self] in
                    Task { await self?.display() }
                }
            )
        case .offline:
            return ErrorUIModel(
                message: "You're offline and have no cached albums.",
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

extension AlbumListViewModel {
    public struct UserIconUIModel: Equatable, Sendable {
        public let avatarUrl: URL?
        @EquatableNoop public var didTap: @MainActor @Sendable () -> Void

        public init(avatarUrl: URL?, didTap: @escaping @MainActor @Sendable () -> Void) {
            self.avatarUrl = avatarUrl
            self.didTap = didTap
        }
    }

    public enum DisplayResult: Equatable {
        case loading
        case success(ListData)
        case failure(ErrorUIModel)
    }

    public struct ListData: Equatable {
        public let albums: [Album]
        public let items: [AlbumItemUIModel]
        public let currentPage: Int
        public let hasMore: Bool

        public init(albums: [Album], items: [AlbumItemUIModel], currentPage: Int, hasMore: Bool) {
            self.albums = albums
            self.items = items
            self.currentPage = currentPage
            self.hasMore = hasMore
        }
    }

    public struct AlbumItemUIModel: Equatable, Identifiable {
        public let id: UUID
        public let title: String
        public let coverImageUrl: URL?
        public let syncStatus: SyncStatus
        @EquatableNoop public var didTap: @MainActor () -> Void

        public init(id: UUID, title: String, coverImageUrl: URL?, syncStatus: SyncStatus, didTap: @escaping @MainActor () -> Void) {
            self.id = id
            self.title = title
            self.coverImageUrl = coverImageUrl
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
