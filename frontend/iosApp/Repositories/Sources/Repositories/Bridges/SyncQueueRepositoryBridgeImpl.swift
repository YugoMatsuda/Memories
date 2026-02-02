import Foundation
import Combine
import Domains
@preconcurrency import Shared

/// Swift implementation of SyncQueueRepositoryBridge
public final class SyncQueueRepositoryBridgeImpl: Shared.SyncQueueRepositoryBridge, @unchecked Sendable {
    private let repository: SyncQueueRepositoryProtocol
    private var callback: Shared.SyncQueueStateCallback?
    private var cancellable: AnyCancellable?

    public init(repository: SyncQueueRepositoryProtocol) {
        self.repository = repository
    }

    public func __enqueue(operation: Shared.SyncOperation) async throws {
        try await repository.enqueue(operation)
    }

    public func __peek() async throws -> [Shared.SyncOperation] {
        await repository.peek()
    }

    public func __getAll() async throws -> [Shared.SyncOperation] {
        await repository.getAll()
    }

    public func __remove(id: Shared.LocalId) async throws {
        try await repository.remove(id: id.uuid)
    }

    public func __updateStatus(id: Shared.LocalId, status: Shared.SyncOperationStatus, errorMessage: String?) async throws {
        try await repository.updateStatus(id: id.uuid, status: status.toSwift(), errorMessage: errorMessage)
    }

    public func tryStartSyncing() -> Bool {
        repository.tryStartSyncing()
    }

    public func stopSyncing() {
        repository.stopSyncing()
    }

    public func __refreshState() async throws {
        await repository.refreshState()
    }

    public func registerStateCallback(callback: Shared.SyncQueueStateCallback) {
        self.callback = callback
        cancellable = repository.statePublisher
            .sink { [weak self] state in
                let kmpState = Shared.SyncQueueState(
                    pendingCount: Int32(state.pendingCount),
                    isSyncing: state.isSyncing
                )
                self?.callback?.onStateChanged(state: kmpState)
            }
    }

    public func unregisterStateCallback() {
        cancellable?.cancel()
        cancellable = nil
        callback = nil
    }
}

// MARK: - Conversion Helper

extension Shared.SyncOperationStatus {
    func toSwift() -> SyncOperationStatus {
        switch self {
        case .pending: return .pending
        case .inProgress: return .inProgress
        case .failed: return .failed
        default: return .pending
        }
    }
}
