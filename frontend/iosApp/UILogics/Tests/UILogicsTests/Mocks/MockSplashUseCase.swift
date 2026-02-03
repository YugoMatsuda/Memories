import Foundation
import UseCases
@preconcurrency import Shared

final class MockSplashUseCase: SplashUseCaseProtocol, @unchecked Sendable {
    var launchAppResult: Shared.LaunchAppResult = .Failure(error: .unknown)
    var clearSessionCalled = false

    func launchApp() async -> Shared.LaunchAppResult {
        return launchAppResult
    }

    func clearSession() {
        clearSessionCalled = true
    }
}
