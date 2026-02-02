import Foundation
import Combine
import Domains
import Repositories

public struct SyncQueuesUseCase: SyncQueuesUseCaseProtocol, Sendable {
    private let syncQueueRepository: SyncQueueRepositoryProtocol
    private let albumRepository: AlbumRepositoryProtocol
    private let memoryRepository: MemoryRepositoryProtocol
    private let userRepository: UserRepositoryProtocol

    public init(
        syncQueueRepository: SyncQueueRepositoryProtocol,
        albumRepository: AlbumRepositoryProtocol,
        memoryRepository: MemoryRepositoryProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.syncQueueRepository = syncQueueRepository
        self.albumRepository = albumRepository
        self.memoryRepository = memoryRepository
        self.userRepository = userRepository
    }

    public func observeState() -> AnyPublisher<Void, Never> {
        syncQueueRepository.statePublisher
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public func getAll() async -> [SyncQueueItem] {
        let operations = await syncQueueRepository.getAll()

        var items: [SyncQueueItem] = []
        for operation in operations {
            let (title, serverId) = await fetchEntityDetails(for: operation)
            items.append(SyncQueueItem(
                operation: operation,
                entityTitle: title,
                entityServerId: serverId
            ))
        }
        return items
    }

    private func fetchEntityDetails(for operation: SyncOperation) async -> (title: String?, serverId: Int?) {
        switch operation.entityType {
        case .album:
            if let album = await albumRepository.get(byLocalId: operation.localId) {
                return (album.title, album.id)
            }
        case .memory:
            if let memory = await memoryRepository.get(byLocalId: operation.localId) {
                return (memory.title, memory.serverId)
            }
        case .user:
            if let user = await userRepository.get() {
                return (user.name, user.id)
            }
        }
        return (nil, nil)
    }
}
