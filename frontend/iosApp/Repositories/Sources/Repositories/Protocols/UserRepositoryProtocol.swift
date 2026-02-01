import Foundation
import Combine
import Domains

public protocol UserRepositoryProtocol: Sendable {
    var userId: Int { get }

    // Read
    func get() async -> User?

    // Write (always fires event)
    func set(_ user: User) async throws

    // Notify (fires event without writing to DB)
    func notify(_ user: User)

    // Publisher
    var userPublisher: AnyPublisher<User, Never> { get }
}
