import Foundation
import Domains
import UseCases

@MainActor
public final class LoginViewModel: ObservableObject {
    private let loginUseCase: LoginUseCaseProtocol
    private let onSuccess: (AuthSession) -> Void

    @Published public var username: String = ""
    @Published public var password: String = ""
    @Published public var loginState: LoginState = .idle

    public var continueAsItem: ContinueAsUIModel?

    public init(
        loginUseCase: LoginUseCaseProtocol,
        onSuccess: @escaping (AuthSession) -> Void,
        continueAsItem: ContinueAsUIModel? = nil
    ) {
        self.loginUseCase = loginUseCase
        self.onSuccess = onSuccess
        self.continueAsItem = continueAsItem
    }

    public func login() async {
        loginState = .loading

        let result = await loginUseCase.login(
            username: username,
            password: password
        )

        switch result {
        case .success(let session):
            loginState = .idle
            onSuccess(session)
        case .failure(let error):
            loginState = .error(message: errorMessage(for: error))
        }
    }

    private func errorMessage(for error: LoginUseCaseModel.LoginResult.Error) -> String {
        switch error {
        case .invalidCredentials:
            return "Invalid username or password"
        case .networkError:
            return "Network error"
        case .serverError:
            return "Server error"
        case .unknown:
            return "Unknown error"
        }
    }
}

extension LoginViewModel {
    public struct ContinueAsUIModel {
        public let userName: String
        public let avatarUrl: URL?
        public let onTap: () -> Void

        public init(userName: String, avatarUrl: URL?, onTap: @escaping () -> Void) {
            self.userName = userName
            self.avatarUrl = avatarUrl
            self.onTap = onTap
        }
    }

    public enum LoginState {
        case idle
        case loading
        case error(message: String)

        public var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }
    }
}
