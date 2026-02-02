import Foundation
import SwiftUI
import Combine
import Domains
import UILogics
import UIComponents
import UseCases

@MainActor
public final class AuthenticatedRouter: AuthenticatedRouterProtocol, ObservableObject {
    @Published public var path = NavigationPath()
    @Published public var sheetItem: AuthenticatedSheet?

    private var cancellables = Set<AnyCancellable>()

    public init(
        pendingDeepLink: DeepLink?,
        deepLinkPublisher: AnyPublisher<DeepLink, Never>
    ) {
        // Cold Start: process pending deep link
        if let deepLink = pendingDeepLink {
            handleDeepLink(deepLink)
        }

        // Warm Start: observe deep link publisher
        deepLinkPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deepLink in
                self?.handleDeepLink(deepLink)
            }
            .store(in: &cancellables)
    }

    private func handleDeepLink(_ deepLink: DeepLink) {
        switch deepLink {
        case .album(let albumId):
            path = NavigationPath()
            path.append(AuthenticatedRoute.albumDetail(.deepLink(id: albumId)))
        }
    }

    public func push(_ route: AuthenticatedRoute) {
        path.append(route)
    }

    public func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    public func popToRoot() {
        path = NavigationPath()
    }

    public func showSheet(_ sheet: AuthenticatedSheet) {
        sheetItem = sheet
    }

    public func dismissSheet() {
        sheetItem = nil
    }
}

@MainActor
public final class AuthenticatedCoordinator: ObservableObject {
    public enum State: Equatable {
        case splash
        case continueAs(User)
        case main
    }

    @Published public var state: State = .splash

    private let factory: AuthenticatedViewModelFactory
    private let hasPreviousSession: Bool
    private let onReLogin: ((String, Int) -> Void)?

    public init(factory: AuthenticatedViewModelFactory, hasPreviousSession: Bool, onReLogin: ((String, Int) -> Void)? = nil) {
        self.factory = factory
        self.hasPreviousSession = hasPreviousSession
        self.onReLogin = onReLogin
    }

    public func makeSplashView() -> SplashView {
        let viewModel = factory.makeSplashViewModel(
            onSuccess: { [weak self] user in
                guard let self else { return }
                if self.hasPreviousSession {
                    self.state = .continueAs(user)
                } else {
                    self.state = .main
                }
            }
        )
        return SplashView(viewModel: viewModel)
    }

    public func makeLoginView(user: User) -> LoginView {
        let continueAsItem = LoginViewModel.ContinueAsUIModel(
            userName: user.name,
            avatarUrl: user.avatarURL,
            onTap: { [weak self] in
                self?.state = .main
            }
        )
        let viewModel = factory.makeLoginViewModel(
            onSuccess: { [weak self] session in
                // New login succeeded, recreate AuthenticatedRootView with new session
                self?.onReLogin?(session.token, session.userIdInt)
            },
            continueAsItem: continueAsItem
        )
        return LoginView(viewModel: viewModel)
    }

    public func makeAlbumListView() -> AlbumListView {
        let viewModel = factory.makeAlbumListViewModel()
        return AlbumListView(viewModel: viewModel)
    }

    public func makeUserProfileView(user: User) -> UserProfileView {
        let viewModel = factory.makeUserProfileViewModel(user: user)
        return UserProfileView(viewModel: viewModel)
    }

    public func makeAlbumDetailView(origin: AlbumDetailOrigin) -> AlbumDetailView {
        let viewModel = factory.makeAlbumDetailViewModel(origin: origin)
        return AlbumDetailView(viewModel: viewModel)
    }

    public func makeAlbumFormView(mode: AlbumFormMode) -> AlbumFormView {
        let viewModel = factory.makeAlbumFormViewModel(mode: mode)
        return AlbumFormView(viewModel: viewModel)
    }

    public func makeMemoryFormView(album: Album) -> MemoryFormView {
        let viewModel = factory.makeMemoryFormViewModel(album: album)
        return MemoryFormView(viewModel: viewModel)
    }

    public func makeSyncQueuesView() -> SyncQueuesView {
        let viewModel = factory.makeSyncQueuesViewModel()
        return SyncQueuesView(viewModel: viewModel)
    }

    @ViewBuilder
    public func destination(for route: AuthenticatedRoute) -> some View {
        switch route {
        case .userProfile(let user):
            makeUserProfileView(user: user)
        case .albumDetail(let origin):
            makeAlbumDetailView(origin: origin)
        case .syncQueues:
            makeSyncQueuesView()
        }
    }

    @ViewBuilder
    public func sheetDestination(for sheet: AuthenticatedSheet) -> some View {
        switch sheet {
        case .albumForm(let mode):
            makeAlbumFormView(mode: mode)
        case .memoryForm(let album):
            makeMemoryFormView(album: album)
        }
    }
}
