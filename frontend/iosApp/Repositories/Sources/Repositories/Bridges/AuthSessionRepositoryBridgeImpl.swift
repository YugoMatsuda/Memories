import Foundation
import Combine
import Domains
@preconcurrency import Shared

/// Swift implementation of AuthSessionRepositoryBridge
public final class AuthSessionRepositoryBridgeImpl: Shared.AuthSessionRepositoryBridge, @unchecked Sendable {
    private let repository: AuthSessionRepositoryProtocol
    private var callback: Shared.SessionChangeCallback?
    private var cancellable: AnyCancellable?

    public init(repository: AuthSessionRepositoryProtocol) {
        self.repository = repository
    }

    public func restore() -> Shared.AuthSession? {
        repository.restore()
    }

    public func getSession() -> Shared.AuthSession? {
        repository.getSession()
    }

    public func save(session: Shared.AuthSession) {
        repository.save(session: session)
    }

    public func clearSession() {
        repository.clearSession()
    }

    public func registerSessionCallback(callback: Shared.SessionChangeCallback) {
        self.callback = callback
        cancellable = repository.getSessionPublisher()
            .sink { [weak self] session in
                self?.callback?.onSessionChanged(session: session)
            }
    }

    public func unregisterSessionCallback() {
        cancellable?.cancel()
        cancellable = nil
        callback = nil
    }
}
