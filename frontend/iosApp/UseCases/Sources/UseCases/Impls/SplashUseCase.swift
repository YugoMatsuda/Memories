import Foundation
import APIGateways
import Repositories
import Domains
import APIClients

public struct SplashUseCase: SplashUseCaseProtocol, Sendable {
    private let userGateway: any UserGatewayProtocol
    private let userRepository: any UserRepositoryProtocol
    private let authSessionRepository: any AuthSessionRepositoryProtocol
    private let reachabilityRepository: any ReachabilityRepositoryProtocol

    public init(
        userGateway: any UserGatewayProtocol,
        userRepository: any UserRepositoryProtocol,
        authSessionRepository: any AuthSessionRepositoryProtocol,
        reachabilityRepository: any ReachabilityRepositoryProtocol
    ) {
        self.userGateway = userGateway
        self.userRepository = userRepository
        self.authSessionRepository = authSessionRepository
        self.reachabilityRepository = reachabilityRepository
    }

    public func launchApp() async -> SplashUseCaseModel.LaunchAppResult {
        if reachabilityRepository.isConnected {
            do {
                let response = try await userGateway.getUser()
                let user = UserMapper.toDomain(response)
                do {
                    try await userRepository.set(user)
                } catch {
                    print("[SplashUseCase] Failed to save user to cache: \(error)")
                }
                return .success(user)
            } catch let error as APIError {
                // Fallback to cache on error
                if let cachedUser = await userRepository.get() {
                    userRepository.notify(cachedUser)
                    return .success(cachedUser)
                }
                return .failure(mapError(error))
            } catch {
                // Fallback to cache on error
                if let cachedUser = await userRepository.get() {
                    userRepository.notify(cachedUser)
                    return .success(cachedUser)
                }
                return .failure(.unknown)
            }
        } else {
            // Offline: use cache
            if let cachedUser = await userRepository.get() {
                userRepository.notify(cachedUser)
                return .success(cachedUser)
            }
            return .failure(.offlineNoCache)
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
