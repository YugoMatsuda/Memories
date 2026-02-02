import Foundation
import Combine
import Domains
@preconcurrency import Shared

/// Swift implementation of MemoryRepositoryBridge
public final class MemoryRepositoryBridgeImpl: Shared.MemoryRepositoryBridge, @unchecked Sendable {
    private let repository: MemoryRepositoryProtocol
    private var callback: Shared.MemoryChangeCallback?
    private var cancellable: AnyCancellable?

    public init(repository: MemoryRepositoryProtocol) {
        self.repository = repository
    }

    public func __getAll(albumLocalId: Shared.LocalId) async throws -> [Shared.Memory] {
        await repository.getAll(albumLocalId: albumLocalId.uuid)
    }

    public func __getByLocalId(localId: Shared.LocalId) async throws -> Shared.Memory? {
        await repository.get(byLocalId: localId.uuid)
    }

    public func __syncSet(memories: [Shared.Memory], albumLocalId: Shared.LocalId) async throws {
        try await repository.syncSet(memories, albumLocalId: albumLocalId.uuid)
    }

    public func __syncAppend(memories: [Shared.Memory]) async throws {
        try await repository.syncAppend(memories)
    }

    public func __insert(memory: Shared.Memory) async throws {
        try await repository.insert(memory)
    }

    public func __markAsSynced(localId: Shared.LocalId, serverId: Int32) async throws {
        try await repository.markAsSynced(localId: localId.uuid, serverId: Int(serverId))
    }

    public func registerChangeCallback(callback: Shared.MemoryChangeCallback) {
        self.callback = callback
        cancellable = repository.localChangePublisher
            .sink { [weak self] event in
                switch event {
                case .created(let memory):
                    self?.callback?.onCreated(memory: memory)
                }
            }
    }

    public func unregisterChangeCallback() {
        cancellable?.cancel()
        cancellable = nil
        callback = nil
    }
}
