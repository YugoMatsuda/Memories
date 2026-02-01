import Foundation
import Combine
import Domains
import Repositories

@MainActor
public final class SyncQueuesViewModel: ObservableObject {
    @Published public private(set) var operations: [SyncOperation] = []

    private let syncQueueRepository: SyncQueueRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    public init(syncQueueRepository: SyncQueueRepositoryProtocol) {
        self.syncQueueRepository = syncQueueRepository

        syncQueueRepository.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadOperations()
                }
            }
            .store(in: &cancellables)
    }

    public func onAppear() {
        Task {
            await loadOperations()
        }
    }

    private func loadOperations() async {
        operations = await syncQueueRepository.getAll()
    }
}
