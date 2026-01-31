import Foundation
import APIGateways
import Repositories
import Domains
import APIClients

public struct SplashUseCase: SplashUseCaseProtocol, Sendable {
    private let userGateway: any UserGatewayProtocol
    private let userRepository: any UserRepositoryProtocol
    private let authSessionRepository: any AuthSessionRepositoryProtocol

    public init(
        userGateway: any UserGatewayProtocol,
        userRepository: any UserRepositoryProtocol,
        authSessionRepository: any AuthSessionRepositoryProtocol
    ) {
        self.userGateway = userGateway
        self.userRepository = userRepository
        self.authSessionRepository = authSessionRepository
    }

    public func launchApp() async -> SplashUseCaseModel.LaunchAppResult {
        do {
            let response = try await userGateway.getUser()
            let user = UserMapper.toDomain(response)
            userRepository.set(user)
            return .success(user)
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    public func clearSession() {
        authSessionRepository.clearSession()
    }

    private func mapError(_ error: APIError) -> SplashUseCaseModel.LaunchAppResult.Error {
        switch error {
        case .invalidAPIToken:
            return .sessionExpired
        case .networkError, .timeout:
            return .networkError
        case .serverError, .serviceUnavailable:
            return .serverError
        default:
            return .unknown
        }
    }
}
