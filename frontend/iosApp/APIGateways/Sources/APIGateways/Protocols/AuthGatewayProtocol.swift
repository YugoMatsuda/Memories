import Foundation
@preconcurrency import Shared

public protocol AuthGatewayProtocol: Sendable {
    func login(username: String, password: String) async throws -> Shared.TokenResponse
}
