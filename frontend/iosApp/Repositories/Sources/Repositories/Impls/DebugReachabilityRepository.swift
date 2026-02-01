import Foundation
import Combine

public final class DebugReachabilityRepository: ReachabilityRepositoryProtocol, @unchecked Sendable {
    private let connectedSubject: CurrentValueSubject<Bool, Never>

    public var isConnected: Bool {
        connectedSubject.value
    }

    public var isConnectedPublisher: AnyPublisher<Bool, Never> {
        connectedSubject.eraseToAnyPublisher()
    }

    public init(isOnline: Bool) {
        self.connectedSubject = CurrentValueSubject(isOnline)
    }

    public func setOnline(_ isOnline: Bool) {
        connectedSubject.send(isOnline)
    }
}
