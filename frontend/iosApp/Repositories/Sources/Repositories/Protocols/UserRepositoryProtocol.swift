import Foundation
import Domains

public protocol UserRepositoryProtocol: Sendable {
    init()
    func get() -> User?
    func set(_ user: User)
}
