import Foundation
import Combine
import Domains

public protocol RootUseCaseProtocol {
    var observeDidLogout: AnyPublisher<Void, Never> { get }
    func checkPreviousSession() -> RootUseCaseModel.CheckPreviousSessionResult
}

public enum RootUseCaseModel {
    public enum CheckPreviousSessionResult {
        case loggedIn(session: AuthSession)
        case notLoggedIn
    }
}
