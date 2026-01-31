import Foundation
import Combine
import Domains
import UseCases
import Utilities

@MainActor
public final class AlbumListViewModel: ObservableObject {
    @Published public private(set) var userIcon: UserIconUIModel?

    private let router: AuthenticatedRouterProtocol
    private var cancellables = Set<AnyCancellable>()

    public init(
        albumListUseCase: AlbumListUseCaseProtocol,
        router: AuthenticatedRouterProtocol
    ) {
        self.router = router

        albumListUseCase.observeUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                self.userIcon = UserIconUIModel(
                    avatarUrl: user.avatarUrl,
                    didTap: { [weak self] in
                        self?.router.push(.userProfile(user))
                    }
                )
            }
            .store(in: &cancellables)
    }

    public func showCreateAlbumForm() {
        router.showSheet(.albumForm(.create))
    }

    public func showEditAlbumForm(album: Album) {
        router.showSheet(.albumForm(.edit(album)))
    }
}

extension AlbumListViewModel {
    public struct UserIconUIModel: Equatable, Sendable {
        public let avatarUrl: URL?
        @EquatableNoop public var didTap: @MainActor @Sendable () -> Void

        public init(avatarUrl: URL?, didTap: @escaping @MainActor @Sendable () -> Void) {
            self.avatarUrl = avatarUrl
            self.didTap = didTap
        }
    }
}
