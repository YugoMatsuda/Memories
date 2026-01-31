import Foundation
import Combine
import Domains

public protocol AlbumListUseCaseProtocol: Sendable {
    var observeUser: AnyPublisher<User, Never> { get }
}
