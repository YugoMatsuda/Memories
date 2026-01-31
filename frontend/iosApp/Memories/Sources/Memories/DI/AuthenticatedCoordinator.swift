import Foundation
import SwiftUI
import Domains
import UILogics
import UIComponents

@MainActor
public final class AuthenticatedRouter: AuthenticatedRouterProtocol, ObservableObject {
    @Published public var path = NavigationPath()
    @Published public var sheetItem: AuthenticatedSheet?

    public init() {}

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

    public init(factory: AuthenticatedViewModelFactory, hasPreviousSession: Bool) {
        self.factory = factory
        self.hasPreviousSession = hasPreviousSession
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
            },
            onSessionExpired: {
                AppConfig.authSessionRepository.clearSession()
            }
        )
        return SplashView(viewModel: viewModel)
    }

    public func makeLoginView(user: User) -> LoginView {
        let continueAsItem = LoginViewModel.ContinueAsUIModel(
            userName: user.name,
            avatarUrl: user.avatarUrl,
            onTap: { [weak self] in
                self?.state = .main
            }
        )
        let viewModel = factory.makeLoginViewModel(
            onSuccess: { [weak self] _ in
                // New login succeeded, go to splash to fetch new user
                self?.state = .splash
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

    public func makeAlbumFormView(mode: AlbumFormMode) -> AlbumFormView {
        let viewModel = factory.makeAlbumFormViewModel(mode: mode)
        return AlbumFormView(viewModel: viewModel)
    }

    @ViewBuilder
    public func destination(for route: AuthenticatedRoute) -> some View {
        switch route {
        case .userProfile(let user):
            makeUserProfileView(user: user)
        }
    }

    @ViewBuilder
    public func sheetDestination(for sheet: AuthenticatedSheet) -> some View {
        switch sheet {
        case .albumForm(let mode):
            makeAlbumFormView(mode: mode)
        }
    }
}
