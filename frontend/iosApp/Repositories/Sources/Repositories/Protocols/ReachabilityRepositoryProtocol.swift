import Foundation
import Combine

public protocol ReachabilityRepositoryProtocol: Sendable {
    var isConnected: Bool { get }
    var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
}
