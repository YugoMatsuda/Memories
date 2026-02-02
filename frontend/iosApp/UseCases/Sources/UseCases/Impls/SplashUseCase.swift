import Foundation
@preconcurrency import Shared
import Repositories
import Domains
import APIGateways

public struct SplashUseCase: SplashUseCaseProtocol, @unchecked Sendable {
    private let userGateway: UserGatewayProtocol
    private let userRepository: UserRepositoryProtocol
    private let authSessionRepository: AuthSessionRepositoryProtocol
    private let reachabilityRepository: ReachabilityRepositoryProtocol
    private let syncQueueRepository: SyncQueueRepositoryProtocol

    public init(
        userGateway: UserGatewayProtocol,
        userRepository: UserRepositoryProtocol,
        authSessionRepository: AuthSessionRepositoryProtocol,
        reachabilityRepository: ReachabilityRepositoryProtocol,
        syncQueueRepository: SyncQueueRepositoryProtocol
    ) {
        self.userGateway = userGateway
        self.userRepository = userRepository
        self.authSessionRepository = authSessionRepository
        self.reachabilityRepository = reachabilityRepository
        self.syncQueueRepository = syncQueueRepository
    }

    public func launchApp() async -> SplashUseCaseModel.LaunchAppResult {
        await syncQueueRepository.refreshState()
        if reachabilityRepository.isConnected {
            do {
                let response = try await userGateway.getUser()
                let user = Shared.UserMapper.shared.toDomain(response: response)
                do {
                    try await userRepository.set(user)
                } catch {
                    print("[SplashUseCase] Failed to save user to cache: \(error)")
                }
                return .success(user)
            } catch let error as Shared.ApiError {
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

    private func mapError(_ error: Shared.ApiError) -> SplashUseCaseModel.LaunchAppResult.Error {
        switch error {
        case is Shared.ApiError.InvalidApiToken:
            return .sessionExpired
        case is Shared.ApiError.NetworkError, is Shared.ApiError.Timeout:
            return .networkError
        case is Shared.ApiError.ServerError, is Shared.ApiError.ServiceUnavailable:
            return .serverError
        default:
            return .unknown
        }
    }
}
