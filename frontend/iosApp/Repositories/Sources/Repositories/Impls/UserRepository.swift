import Foundation
import Domains

public final class UserRepository: UserRepositoryProtocol, @unchecked Sendable {
    private var user: User?

    public init() {}

    public func get() -> User? {
        user
    }

    public func set(_ user: User) {
        self.user = user
    }
}
