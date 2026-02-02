import Foundation
import Domains
@preconcurrency import Shared

/// Adapter that wraps KMP LoginUseCase to conform to Swift LoginUseCaseProtocol
public final class LoginUseCaseAdapter: LoginUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.LoginUseCase

    public init(kmpUseCase: Shared.LoginUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func login(username: String, password: String) async -> LoginUseCaseModel.LoginResult {
        do {
            let result = try await kmpUseCase.login(username: username, password: password)
            if let success = result as? Shared.LoginResult.Success {
                let session = AuthSession.create(
                    token: success.session.token,
                    userId: Int(success.session.userId)
                )
                return .success(session)
            } else if let failure = result as? Shared.LoginResult.Failure {
                return .failure(mapError(failure.error))
            }
            return .failure(.unknown)
        } catch {
            return .failure(.unknown)
        }
    }

    private func mapError(_ error: Shared.LoginError) -> LoginUseCaseModel.LoginResult.Error {
        switch error {
        case .invalidCredentials: return .invalidCredentials
        case .networkError: return .networkError
        case .serverError: return .serverError
        default: return .unknown
        }
    }
}
