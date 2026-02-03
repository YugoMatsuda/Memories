import Foundation
import UseCases
@preconcurrency import Shared

final class MockLoginUseCase: LoginUseCaseProtocol, @unchecked Sendable {
    var loginResult: Shared.LoginResult = .Failure(error: .unknown)
    var capturedUsername: String?
    var capturedPassword: String?

    func login(username: String, password: String) async -> Shared.LoginResult {
        capturedUsername = username
        capturedPassword = password
        return loginResult
    }
}
