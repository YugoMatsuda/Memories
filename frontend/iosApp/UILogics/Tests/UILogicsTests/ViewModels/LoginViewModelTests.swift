import Testing
import Foundation
@testable import UILogics
import Domains
@preconcurrency import Shared

@MainActor
@Suite("LoginViewModel Tests")
struct LoginViewModelTests {

    @Test("Initial state is idle")
    func initialState() {
        let mockUseCase = MockLoginUseCase()
        let viewModel = LoginViewModel(
            loginUseCase: mockUseCase,
            onSuccess: { _ in }
        )

        #expect(viewModel.loginState == .idle)
        #expect(viewModel.username == "")
        #expect(viewModel.password == "")
    }

    @Test("login success calls onSuccess callback")
    func loginSuccessCallsCallback() async {
        let mockUseCase = MockLoginUseCase()
        let session = TestHelpers.createAuthSession(token: "test-token", userId: 42)
        mockUseCase.loginResult = .Success(session: session)

        var callbackSession: AuthSession?
        let viewModel = LoginViewModel(
            loginUseCase: mockUseCase,
            onSuccess: { callbackSession = $0 }
        )

        viewModel.username = "testuser"
        viewModel.password = "testpass"

        await viewModel.login()

        #expect(callbackSession?.token == "test-token")
        #expect(callbackSession?.userId == 42)
        #expect(viewModel.loginState == .idle)
    }

    @Test("login passes credentials to useCase")
    func loginPassesCredentials() async {
        let mockUseCase = MockLoginUseCase()
        let session = TestHelpers.createAuthSession()
        mockUseCase.loginResult = .Success(session: session)

        let viewModel = LoginViewModel(
            loginUseCase: mockUseCase,
            onSuccess: { _ in }
        )

        viewModel.username = "myuser"
        viewModel.password = "mypass"

        await viewModel.login()

        #expect(mockUseCase.capturedUsername == "myuser")
        #expect(mockUseCase.capturedPassword == "mypass")
    }

    @Test("login invalidCredentials sets error state")
    func loginInvalidCredentialsSetsError() async {
        let mockUseCase = MockLoginUseCase()
        mockUseCase.loginResult = .Failure(error: .invalidCredentials)

        let viewModel = LoginViewModel(
            loginUseCase: mockUseCase,
            onSuccess: { _ in }
        )

        await viewModel.login()

        if case .error(let message) = viewModel.loginState {
            #expect(message == "Invalid username or password")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("login networkError sets error state")
    func loginNetworkErrorSetsError() async {
        let mockUseCase = MockLoginUseCase()
        mockUseCase.loginResult = .Failure(error: .networkError)

        let viewModel = LoginViewModel(
            loginUseCase: mockUseCase,
            onSuccess: { _ in }
        )

        await viewModel.login()

        if case .error(let message) = viewModel.loginState {
            #expect(message == "Network error")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("login serverError sets error state")
    func loginServerErrorSetsError() async {
        let mockUseCase = MockLoginUseCase()
        mockUseCase.loginResult = .Failure(error: .serverError)

        let viewModel = LoginViewModel(
            loginUseCase: mockUseCase,
            onSuccess: { _ in }
        )

        await viewModel.login()

        if case .error(let message) = viewModel.loginState {
            #expect(message == "Server error")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("loginState isLoading returns correct value")
    func loginStateIsLoading() {
        #expect(LoginViewModel.LoginState.idle.isLoading == false)
        #expect(LoginViewModel.LoginState.loading.isLoading == true)
        #expect(LoginViewModel.LoginState.error(message: "test").isLoading == false)
    }
}

// MARK: - LoginState Equatable

extension LoginViewModel.LoginState: Equatable {
    public static func == (lhs: LoginViewModel.LoginState, rhs: LoginViewModel.LoginState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}
