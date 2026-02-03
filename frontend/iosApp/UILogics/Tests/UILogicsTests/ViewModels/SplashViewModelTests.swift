import Testing
import Foundation
@testable import UILogics
import Domains
@preconcurrency import Shared

@MainActor
@Suite("SplashViewModel Tests")
struct SplashViewModelTests {

    @Test("Initial state is .initial")
    func initialState() {
        let mockUseCase = MockSplashUseCase()
        let viewModel = SplashViewModel(
            splashUseCase: mockUseCase,
            onSuccess: { _ in }
        )

        #expect(viewModel.state == .initial)
    }

    @Test("launchApp sets state to loading")
    func launchAppSetsLoading() async {
        let mockUseCase = MockSplashUseCase()
        let user = TestHelpers.createUser()
        mockUseCase.launchAppResult = .Success(user: user)

        var successUser: User?
        let viewModel = SplashViewModel(
            splashUseCase: mockUseCase,
            onSuccess: { successUser = $0 }
        )

        await viewModel.launchApp()

        #expect(successUser != nil)
        #expect(successUser?.name == "Test User")
    }

    @Test("launchApp success calls onSuccess callback")
    func launchAppSuccessCallsCallback() async {
        let mockUseCase = MockSplashUseCase()
        let user = TestHelpers.createUser(name: "Demo User")
        mockUseCase.launchAppResult = .Success(user: user)

        var callbackUser: User?
        let viewModel = SplashViewModel(
            splashUseCase: mockUseCase,
            onSuccess: { callbackUser = $0 }
        )

        await viewModel.launchApp()

        #expect(callbackUser?.name == "Demo User")
    }

    @Test("launchApp sessionExpired sets error state")
    func launchAppSessionExpiredSetsError() async {
        let mockUseCase = MockSplashUseCase()
        mockUseCase.launchAppResult = .Failure(error: .sessionExpired)

        let viewModel = SplashViewModel(
            splashUseCase: mockUseCase,
            onSuccess: { _ in }
        )

        await viewModel.launchApp()

        if case .error(let errorItem) = viewModel.state {
            #expect(errorItem.message == "Session has expired")
            #expect(errorItem.buttonTitle == "Go to Login")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("launchApp networkError sets error state with retry")
    func launchAppNetworkErrorSetsError() async {
        let mockUseCase = MockSplashUseCase()
        mockUseCase.launchAppResult = .Failure(error: .networkError)

        let viewModel = SplashViewModel(
            splashUseCase: mockUseCase,
            onSuccess: { _ in }
        )

        await viewModel.launchApp()

        if case .error(let errorItem) = viewModel.state {
            #expect(errorItem.message == "Network error occurred")
            #expect(errorItem.buttonTitle == "Retry")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("launchApp offlineNoCache sets error state")
    func launchAppOfflineNoCacheSetsError() async {
        let mockUseCase = MockSplashUseCase()
        mockUseCase.launchAppResult = .Failure(error: .offlineNoCache)

        let viewModel = SplashViewModel(
            splashUseCase: mockUseCase,
            onSuccess: { _ in }
        )

        await viewModel.launchApp()

        if case .error(let errorItem) = viewModel.state {
            #expect(errorItem.message == "You're offline with no cached data")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("launchApp serverError sets error state")
    func launchAppServerErrorSetsError() async {
        let mockUseCase = MockSplashUseCase()
        mockUseCase.launchAppResult = .Failure(error: .serverError)

        let viewModel = SplashViewModel(
            splashUseCase: mockUseCase,
            onSuccess: { _ in }
        )

        await viewModel.launchApp()

        if case .error(let errorItem) = viewModel.state {
            #expect(errorItem.message == "Server error occurred")
        } else {
            Issue.record("Expected error state")
        }
    }
}

// MARK: - State Equatable for Testing

extension SplashViewModel.State: Equatable {
    public static func == (lhs: SplashViewModel.State, rhs: SplashViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial):
            return true
        case (.loading(let lhsMessage), .loading(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.message == rhsError.message
        default:
            return false
        }
    }
}
