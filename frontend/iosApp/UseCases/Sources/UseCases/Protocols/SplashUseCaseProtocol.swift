import Foundation
import Domains

public protocol SplashUseCaseProtocol: Sendable {
    func launchApp() async -> SplashUseCaseModel.LaunchAppResult
    func clearSession()
}

public enum SplashUseCaseModel {
    public enum LaunchAppResult {
        case success(User)
        case failure(Error)

        public enum Error {
            case sessionExpired
            case networkError
            case serverError
            case offlineNoCache
            case unknown
        }
    }
}
