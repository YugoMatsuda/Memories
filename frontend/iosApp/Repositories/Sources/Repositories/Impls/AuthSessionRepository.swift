import Foundation
import Combine
import Domains
import Utilities

public final class AuthSessionRepository: AuthSessionRepositoryProtocol, @unchecked Sendable {
    private let sessionSubject = CurrentValueSubject<AuthSession?, Never>(nil)

    public init() {}

    public func restore() -> AuthSession? {
        guard let token = KeychainHelper.get(.accessToken),
              let userIdString = KeychainHelper.get(.userId),
              let userId = Int(userIdString) else {
            return nil
        }
        let session = AuthSession(token: token, userId: userId)
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
        KeychainHelper.set(String(session.userId), for: .userId)
        sessionSubject.send(session)
    }

    public func clearSession() {
        KeychainHelper.remove(.accessToken)
        KeychainHelper.remove(.userId)
        sessionSubject.send(nil)
    }
}
