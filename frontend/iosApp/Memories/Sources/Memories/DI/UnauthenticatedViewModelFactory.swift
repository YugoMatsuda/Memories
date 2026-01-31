import Foundation
import Domains
import UILogics

@MainActor
public final class UnauthenticatedViewModelFactory {
    public init() {}

    public func makeLoginViewModel(
        onSuccess: @escaping (AuthSession) -> Void,
        continueAsItem: LoginViewModel.ContinueAsUIModel? = nil
    ) -> LoginViewModel {
        LoginViewModel(
            loginUseCase: AppConfig.loginUseCase,
            onSuccess: onSuccess,
            continueAsItem: continueAsItem
        )
    }
}
