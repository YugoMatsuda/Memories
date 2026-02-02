import Foundation
import Combine
import Domains
@preconcurrency import Shared

/// Adapter that wraps KMP SyncQueuesUseCase to conform to Swift SyncQueuesUseCaseProtocol
public final class SyncQueuesUseCaseAdapter: SyncQueuesUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.SyncQueuesUseCase

    public init(kmpUseCase: Shared.SyncQueuesUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    // MARK: - Observe (KMP Flow → Swift Publisher)

    public func observeState() -> AnyPublisher<Void, Never> {
        kmpUseCase.observeState()
            .asPublisher()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Actions (delegated to KMP UseCase)

    public func getAll() async -> [SyncQueueItem] {
        do {
            let kmpItems = try await kmpUseCase.getAll()
            return kmpItems.map { kmpItem in
                SyncQueueItem(
                    operation: kmpItem.operation,
                    entityTitle: kmpItem.entityTitle,
                    entityServerId: kmpItem.entityServerId?.intValue
                )
            }
        } catch {
            return []
        }
    }
}
