import Foundation
import Domains
@preconcurrency import Shared

// MARK: - Protocol

public protocol LoginUseCaseProtocol: Sendable {
    func login(username: String, password: String) async -> Shared.LoginResult
}

// MARK: - Adapter

public final class LoginUseCaseAdapter: LoginUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.LoginUseCase

    public init(kmpUseCase: Shared.LoginUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func login(username: String, password: String) async -> Shared.LoginResult {
        do {
            return try await kmpUseCase.login(username: username, password: password)
        } catch {
            return Shared.LoginResult.Failure(error: .unknown)
        }
    }
}
