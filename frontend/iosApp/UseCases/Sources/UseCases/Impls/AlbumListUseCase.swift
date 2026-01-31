import Foundation
import Combine
import Domains

public final class AlbumListUseCase: AlbumListUseCaseProtocol, @unchecked Sendable {
    private let userSubject: CurrentValueSubject<User, Never>

    public var observeUser: AnyPublisher<User, Never> {
        userSubject.eraseToAnyPublisher()
    }

    public init(user: User) {
        self.userSubject = CurrentValueSubject(user)
    }

    public func updateUser(_ user: User) {
        userSubject.send(user)
    }
}
