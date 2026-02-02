import Foundation
import Combine
import Domains
@preconcurrency import Shared

/// Swift implementation of UserRepositoryBridge
public final class UserRepositoryBridgeImpl: Shared.UserRepositoryBridge, @unchecked Sendable {
    private let repository: UserRepositoryProtocol
    private var callback: Shared.UserChangeCallback?
    private var cancellable: AnyCancellable?

    public init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    public var userId: Int32 {
        Int32(repository.userId)
    }

    public func __get() async throws -> Shared.User? {
        await repository.get()
    }

    public func __set(user: Shared.User) async throws {
        try await repository.set(user)
    }

    public func notify(user: Shared.User) {
        repository.notify(user)
    }

    public func registerChangeCallback(callback: Shared.UserChangeCallback) {
        self.callback = callback
        cancellable = repository.userPublisher
            .sink { [weak self] user in
                self?.callback?.onUserChanged(user: user)
            }
    }

    public func unregisterChangeCallback() {
        cancellable?.cancel()
        cancellable = nil
        callback = nil
    }
}
