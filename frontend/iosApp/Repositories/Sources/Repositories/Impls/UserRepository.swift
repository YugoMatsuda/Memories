import Foundation
import Combine
import Domains

public final class UserRepository: UserRepositoryProtocol, @unchecked Sendable {
    public let userId: Int
    private let userSubject = CurrentValueSubject<User?, Never>(nil)

    public var userPublisher: AnyPublisher<User?, Never> {
        userSubject.eraseToAnyPublisher()
    }

    public init(userId: Int) {
        self.userId = userId
    }

    public func get() -> User? {
        userSubject.value
    }

    public func set(_ user: User) {
        userSubject.send(user)
    }
}
