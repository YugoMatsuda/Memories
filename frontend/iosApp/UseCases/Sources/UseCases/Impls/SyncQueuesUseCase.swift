import Foundation
import Combine
import Domains
import Repositories

public struct SyncQueuesUseCase: SyncQueuesUseCaseProtocol, Sendable {
    private let syncQueueRepository: SyncQueueRepositoryProtocol

    public init(syncQueueRepository: SyncQueueRepositoryProtocol) {
        self.syncQueueRepository = syncQueueRepository
    }

    public func observeState() -> AnyPublisher<Void, Never> {
        syncQueueRepository.statePublisher
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public func getAll() async -> [SyncOperation] {
        await syncQueueRepository.getAll()
    }
}
