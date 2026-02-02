import Foundation
import Domains
@preconcurrency import Shared
import Repositories
import APIGateways

public struct LoginUseCase: LoginUseCaseProtocol, @unchecked Sendable {
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
            let session = AuthSession.create(token: response.token, userId: Int(response.userId))
            authSessionRepository.save(session: session)
            return .success(session)
        } catch let error as Shared.ApiError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    private func mapError(_ error: Shared.ApiError) -> LoginUseCaseModel.LoginResult.Error {
        switch error {
        case is Shared.ApiError.InvalidApiToken, is Shared.ApiError.Forbidden:
            return .invalidCredentials
        case is Shared.ApiError.NetworkError, is Shared.ApiError.Timeout:
            return .networkError
        case is Shared.ApiError.ServerError, is Shared.ApiError.ServiceUnavailable:
            return .serverError
        default:
            return .unknown
        }
    }
}
