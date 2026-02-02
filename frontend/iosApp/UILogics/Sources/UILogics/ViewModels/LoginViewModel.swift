import Foundation
import Domains
import UseCases
@preconcurrency import Shared

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

        switch onEnum(of: result) {
        case .success(let success):
            loginState = .idle
            onSuccess(success.session)
        case .failure(let failure):
            loginState = .error(message: errorMessage(for: failure.error))
        }
    }

    private func errorMessage(for error: Shared.LoginError) -> String {
        switch error {
        case .invalidCredentials:
            return "Invalid username or password"
        case .networkError:
            return "Network error"
        case .serverError:
            return "Server error"
        default:
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
