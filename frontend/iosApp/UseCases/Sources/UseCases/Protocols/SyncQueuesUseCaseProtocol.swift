import Foundation
import Combine
import Domains

public protocol SyncQueuesUseCaseProtocol: Sendable {
    func observeState() -> AnyPublisher<Void, Never>
    func getAll() async -> [SyncOperation]
}
