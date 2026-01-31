import Foundation
import Combine
import Domains

public protocol AuthSessionRepositoryProtocol: Sendable {
    func restore() -> AuthSession?
    func getSession() -> AuthSession?
    func getSessionPublisher() -> AnyPublisher<AuthSession?, Never>
    func save(session: AuthSession)
    func clearSession()
}
