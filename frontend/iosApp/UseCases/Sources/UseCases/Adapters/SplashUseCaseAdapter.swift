import Foundation
import Domains
@preconcurrency import Shared

/// Adapter that wraps KMP SplashUseCase to conform to Swift SplashUseCaseProtocol
public final class SplashUseCaseAdapter: SplashUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.SplashUseCase

    public init(kmpUseCase: Shared.SplashUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func launchApp() async -> SplashUseCaseModel.LaunchAppResult {
        do {
            let result = try await kmpUseCase.launchApp()
            if let success = result as? Shared.LaunchAppResult.Success {
                return .success(success.user)
            } else if let failure = result as? Shared.LaunchAppResult.Failure {
                return .failure(mapLaunchAppError(failure.error))
            }
            return .failure(.unknown)
        } catch {
            return .failure(.unknown)
        }
    }

    public func clearSession() {
        kmpUseCase.clearSession()
    }

    private func mapLaunchAppError(_ error: Shared.LaunchAppError) -> SplashUseCaseModel.LaunchAppResult.Error {
        switch error {
        case .sessionExpired: return .sessionExpired
        case .networkError: return .networkError
        case .serverError: return .serverError
        case .offlineNoCache: return .offlineNoCache
        default: return .unknown
        }
    }
}
