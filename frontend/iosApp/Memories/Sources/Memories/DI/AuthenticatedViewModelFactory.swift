import Foundation
import Domains
import UILogics
import UIComponents
import UseCases

@MainActor
public final class AuthenticatedViewModelFactory {
    let container: AuthenticatedContainer

    public init(container: AuthenticatedContainer) {
        self.container = container
    }

    public func makeSplashViewModel(
        onSuccess: @escaping (User) -> Void,
        onSessionExpired: @escaping () -> Void
    ) -> SplashViewModel {
        SplashViewModel(
            splashUseCase: container.splashUseCase,
            onSuccess: onSuccess,
            onSessionExpired: onSessionExpired
        )
    }

    public func makeLoginViewModel(
        onSuccess: @escaping (AuthSession) -> Void,
        continueAsItem: LoginViewModel.ContinueAsUIModel?
    ) -> LoginViewModel {
        LoginViewModel(
            loginUseCase: AppConfig.loginUseCase,
            onSuccess: onSuccess,
            continueAsItem: continueAsItem
        )
    }

    public func makeAlbumListViewModel() -> AlbumListViewModel {
        AlbumListViewModel(
            albumListUseCase: container.albumListUseCase,
            router: container.router
        )
    }

    public func makeAlbumFormViewModel(mode: AlbumFormMode) -> AlbumFormViewModel {
        AlbumFormViewModel(mode: mode, useCase: container.albumFormUseCase, router: container.router)
    }

    public func makeUserProfileViewModel(user: User) -> UserProfileViewModel {
        UserProfileViewModel(user: user, useCase: container.userProfileUseCase)
    }
}
