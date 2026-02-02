import Foundation
import Combine
import Domains
import Utilities
@preconcurrency import Shared

// MARK: - Protocol

public protocol RootUseCaseProtocol: Sendable {
    var observeDidLogout: AnyPublisher<Void, Never> { get }
    func checkPreviousSession() -> Shared.CheckPreviousSessionResult
    func handleDeepLink(url: URL) -> Shared.HandleDeepLinkResult
}

// MARK: - Adapter

public final class RootUseCaseAdapter: RootUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.RootUseCase

    public init(kmpUseCase: Shared.RootUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public var observeDidLogout: AnyPublisher<Void, Never> {
        kmpUseCase.observeDidLogout
            .asPublisher()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public func checkPreviousSession() -> Shared.CheckPreviousSessionResult {
        kmpUseCase.checkPreviousSession()
    }

    public func handleDeepLink(url: URL) -> Shared.HandleDeepLinkResult {
        kmpUseCase.handleDeepLink(url: url.absoluteString)
    }
}
