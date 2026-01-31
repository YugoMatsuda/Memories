import Foundation
import Combine
import Domains
import Repositories

public final class AlbumListUseCase: AlbumListUseCaseProtocol, @unchecked Sendable {
    private let userRepository: UserRepositoryProtocol

    public var observeUser: AnyPublisher<User, Never> {
        userRepository.userPublisher
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
}
