import Foundation
import Domains
@preconcurrency import Shared

// MARK: - Protocol

public protocol SplashUseCaseProtocol: Sendable {
    func launchApp() async -> Shared.LaunchAppResult
    func clearSession()
}

// MARK: - Adapter

public final class SplashUseCaseAdapter: SplashUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.SplashUseCase

    public init(kmpUseCase: Shared.SplashUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func launchApp() async -> Shared.LaunchAppResult {
        do {
            return try await kmpUseCase.launchApp()
        } catch {
            return Shared.LaunchAppResult.Failure(error: .unknown)
        }
    }

    public func clearSession() {
        kmpUseCase.clearSession()
    }
}
