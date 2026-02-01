import Foundation
import Domains
import APIGateways
import APIClients
import Repositories

public struct LoginUseCase: LoginUseCaseProtocol, Sendable {
    private let authGateway: AuthGatewayProtocol
    private let authSessionRepository: AuthSessionRepositoryProtocol

    public init(
        authGateway: AuthGatewayProtocol,
        authSessionRepository: AuthSessionRepositoryProtocol
    ) {
        self.authGateway = authGateway
        self.authSessionRepository = authSessionRepository
    }

    public func login(username: String, password: String) async -> LoginUseCaseModel.LoginResult {
        do {
            let response = try await authGateway.login(username: username, password: password)
            let session = AuthSession(token: response.token, userId: response.userId)
            authSessionRepository.save(session: session)
            return .success(session)
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    private func mapError(_ error: APIError) -> LoginUseCaseModel.LoginResult.Error {
        switch error {
        case .invalidAPIToken, .forbidden:
            return .invalidCredentials
        case .networkError, .timeout:
            return .networkError
        case .serverError, .serviceUnavailable:
            return .serverError
        default:
            return .unknown
        }
    }
}
