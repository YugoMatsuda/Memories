import Foundation
import Combine
import Domains

public protocol RootUseCaseProtocol: Sendable {
    var observeDidLogout: AnyPublisher<Void, Never> { get }
    func checkPreviousSession() -> RootUseCaseModel.CheckPreviousSessionResult
    func handleDeepLink(url: URL) -> RootUseCaseModel.HandleDeepLinkResult
}

public enum RootUseCaseModel {
    public enum CheckPreviousSessionResult {
        case loggedIn(session: AuthSession)
        case notLoggedIn
    }

    public enum HandleDeepLinkResult: Equatable {
        case authenticated(DeepLink)
        case notAuthenticated(DeepLink)
        case invalidURL
    }
}
