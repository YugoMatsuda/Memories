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
        onSuccess: @escaping (User) -> Void
    ) -> SplashViewModel {
        SplashViewModel(
            splashUseCase: container.splashUseCase,
            onSuccess: onSuccess
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
        let isNetworkDebugMode: Bool
        switch AppConfig.onlineState {
        case .debug:
            isNetworkDebugMode = true
        case .production:
            isNetworkDebugMode = false
        }
        return AlbumListViewModel(
            albumListUseCase: container.albumListUseCase,
            router: container.router,
            isNetworkDebugMode: isNetworkDebugMode
        )
    }

    public func makeAlbumFormViewModel(mode: AlbumFormMode) -> AlbumFormViewModel {
        AlbumFormViewModel(mode: mode, useCase: container.albumFormUseCase, router: container.router)
    }

    public func makeUserProfileViewModel(user: User) -> UserProfileViewModel {
        UserProfileViewModel(user: user, useCase: container.userProfileUseCase)
    }

    public func makeAlbumDetailViewModel(album: Album) -> AlbumDetailViewModel {
        AlbumDetailViewModel(album: album, albumDetailUseCase: container.albumDetailUseCase, router: container.router)
    }

    public func makeMemoryFormViewModel(album: Album) -> MemoryFormViewModel {
        MemoryFormViewModel(album: album, useCase: container.memoryFormUseCase, router: container.router)
    }

    public func makeSyncQueuesViewModel() -> SyncQueuesViewModel {
        SyncQueuesViewModel(useCase: container.syncQueuesUseCase)
    }
}
