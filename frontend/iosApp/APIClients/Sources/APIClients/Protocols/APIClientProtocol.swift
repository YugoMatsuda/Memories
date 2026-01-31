import Foundation

public protocol APIClientProtocol: Sendable {
    func send(_ apiRequest: some APIRequestProtocol) async throws -> Data
}
