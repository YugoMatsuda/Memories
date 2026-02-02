import Foundation
import Combine
import Domains
@preconcurrency import Shared

/// Adapter that wraps KMP RootUseCase to conform to Swift RootUseCaseProtocol
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

    public func checkPreviousSession() -> RootUseCaseModel.CheckPreviousSessionResult {
        let result = kmpUseCase.checkPreviousSession()
        if let loggedIn = result as? Shared.CheckPreviousSessionResult.LoggedIn {
            let session = AuthSession.create(
                token: loggedIn.session.token,
                userId: Int(loggedIn.session.userId)
            )
            return .loggedIn(session: session)
        }
        return .notLoggedIn
    }

    public func handleDeepLink(url: URL) -> RootUseCaseModel.HandleDeepLinkResult {
        let result = kmpUseCase.handleDeepLink(url: url.absoluteString)
        if let authenticated = result as? Shared.HandleDeepLinkResult.Authenticated {
            guard let deepLink = mapDeepLink(authenticated.deepLink) else {
                return .invalidURL
            }
            return .authenticated(deepLink)
        } else if let notAuthenticated = result as? Shared.HandleDeepLinkResult.NotAuthenticated {
            guard let deepLink = mapDeepLink(notAuthenticated.deepLink) else {
                return .invalidURL
            }
            return .notAuthenticated(deepLink)
        }
        return .invalidURL
    }

    private func mapDeepLink(_ kmpDeepLink: Shared.DeepLink) -> DeepLink? {
        if let album = kmpDeepLink as? Shared.DeepLink.Album {
            return .album(albumId: Int(album.albumId))
        }
        return nil
    }
}
