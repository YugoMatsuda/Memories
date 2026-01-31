import Foundation
import Domains

public protocol LoginUseCaseProtocol: Sendable {
    func login(username: String, password: String) async -> LoginUseCaseModel.LoginResult
}

public enum LoginUseCaseModel {
    public enum LoginResult {
        case success(AuthSession)
        case failure(Error)

        public enum Error {
            case invalidCredentials
            case networkError
            case serverError
            case unknown
        }
    }
}
