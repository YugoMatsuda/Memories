import Foundation
import Combine
import Domains
import Utilities
@preconcurrency import Shared

// MARK: - Protocol

public protocol SyncQueuesUseCaseProtocol: Sendable {
    func observeState() -> AnyPublisher<Void, Never>
    func getAll() async -> [Shared.SyncQueueItem]
}

// MARK: - Adapter

public final class SyncQueuesUseCaseAdapter: SyncQueuesUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.SyncQueuesUseCase

    public init(kmpUseCase: Shared.SyncQueuesUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func observeState() -> AnyPublisher<Void, Never> {
        kmpUseCase.observeState()
            .asPublisher()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public func getAll() async -> [Shared.SyncQueueItem] {
        do {
            return try await kmpUseCase.getAll()
        } catch {
            return []
        }
    }
}
