import Foundation
import Combine
@preconcurrency import Shared

/// Swift implementation of ReachabilityRepositoryBridge
public final class ReachabilityRepositoryBridgeImpl: Shared.ReachabilityRepositoryBridge, @unchecked Sendable {
    private let repository: ReachabilityRepositoryProtocol
    private var callback: Shared.ReachabilityChangeCallback?
    private var cancellable: AnyCancellable?

    public init(repository: ReachabilityRepositoryProtocol) {
        self.repository = repository
    }

    public var isConnected: Bool {
        repository.isConnected
    }

    public func registerReachabilityCallback(callback: Shared.ReachabilityChangeCallback) {
        self.callback = callback
        cancellable = repository.isConnectedPublisher
            .sink { [weak self] isConnected in
                self?.callback?.onReachabilityChanged(isConnected: isConnected)
            }
    }

    public func unregisterReachabilityCallback() {
        cancellable?.cancel()
        cancellable = nil
        callback = nil
    }
}
