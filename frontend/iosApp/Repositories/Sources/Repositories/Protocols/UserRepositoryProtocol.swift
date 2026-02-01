import Foundation
import Combine
import Domains

public protocol UserRepositoryProtocol: Sendable {
    var userId: Int { get }
    var userPublisher: AnyPublisher<User?, Never> { get }
    func get() -> User?
    func set(_ user: User)
}
