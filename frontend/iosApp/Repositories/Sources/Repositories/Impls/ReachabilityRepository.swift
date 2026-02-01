import Foundation
import Combine
import Reachability

public final class ReachabilityRepository: ReachabilityRepositoryProtocol, @unchecked Sendable {
    private let reachability: Reachability
    private let connectedSubject: CurrentValueSubject<Bool, Never>

    public var isConnected: Bool {
        connectedSubject.value
    }

    public var isConnectedPublisher: AnyPublisher<Bool, Never> {
        connectedSubject.eraseToAnyPublisher()
    }

    public init() {
        guard let reachability = try? Reachability() else {
            fatalError("Failed to initialize Reachability")
        }
        self.reachability = reachability
        self.connectedSubject = CurrentValueSubject(reachability.connection != .unavailable)

        reachability.whenReachable = { [weak self] _ in
            self?.connectedSubject.send(true)
        }

        reachability.whenUnreachable = { [weak self] _ in
            self?.connectedSubject.send(false)
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("[ReachabilityRepository] Failed to start notifier: \(error)")
        }
    }

    deinit {
        reachability.stopNotifier()
    }
}
