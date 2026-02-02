import Foundation
import Combine
import Repositories

public struct RootUseCase: RootUseCaseProtocol, Sendable {
    private let authSessionRepository: AuthSessionRepositoryProtocol

    public init(authSessionRepository: AuthSessionRepositoryProtocol) {
        self.authSessionRepository = authSessionRepository
    }

    public var observeDidLogout: AnyPublisher<Void, Never> {
        authSessionRepository.getSessionPublisher()
            .dropFirst()
            .filter { $0 == nil }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public func checkPreviousSession() -> RootUseCaseModel.CheckPreviousSessionResult {
        guard let session = authSessionRepository.restore() else {
            return .notLoggedIn
        }
        return .loggedIn(session: session)
    }

    public func handleDeepLink(url: URL) -> RootUseCaseModel.HandleDeepLinkResult {
        guard let deepLink = DeepLink.parse(url: url) else {
            return .invalidURL
        }

        guard authSessionRepository.restore() != nil else {
            return .notAuthenticated(deepLink)
        }

        return .authenticated(deepLink)
    }
}
