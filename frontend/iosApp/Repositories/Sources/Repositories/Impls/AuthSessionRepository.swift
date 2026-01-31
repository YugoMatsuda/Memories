import Foundation
import Combine
import Domains
import Utilities

public final class AuthSessionRepository: AuthSessionRepositoryProtocol, @unchecked Sendable {
    private let sessionSubject = CurrentValueSubject<AuthSession?, Never>(nil)

    public init() {}

    public func restore() -> AuthSession? {
        guard let token = KeychainHelper.get(.accessToken) else {
            return nil
        }
        let session = AuthSession(token: token)
        sessionSubject.send(session)
        return session
    }

    public func getSession() -> AuthSession? {
        sessionSubject.value
    }

    public func getSessionPublisher() -> AnyPublisher<AuthSession?, Never> {
        sessionSubject.eraseToAnyPublisher()
    }

    public func save(session: AuthSession) {
        KeychainHelper.set(session.token, for: .accessToken)
        sessionSubject.send(session)
    }

    public func clearSession() {
        KeychainHelper.remove(.accessToken)
        sessionSubject.send(nil)
    }
}
