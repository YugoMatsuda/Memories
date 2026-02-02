import Foundation
import Combine
import SwiftData
import Domains

public final class UserRepository: UserRepositoryProtocol, @unchecked Sendable {
    public let userId: Int
    private let database: SwiftDatabase
    private let userSubject = CurrentValueSubject<User?, Never>(nil)

    public var userPublisher: AnyPublisher<User, Never> {
        userSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public init(userId: Int, database: SwiftDatabase) {
        self.userId = userId
        self.database = database
    }

    // MARK: - Read

    public func get() async -> User? {
        let userId = self.userId
        let descriptor = FetchDescriptor<LocalUser>(
            predicate: #Predicate { $0.userId == userId }
        )
        do {
            return try await database.fetch(descriptor).first
        } catch {
            return nil
        }
    }

    // MARK: - Write

    public func set(_ user: User) async throws {
        let userId = Int(user.id)
        try await database.upsert(
            user,
            as: LocalUser.self,
            predicate: #Predicate { $0.userId == userId }
        )
        userSubject.send(user)
    }

    public func notify(_ user: User) {
        userSubject.send(user)
    }
}
