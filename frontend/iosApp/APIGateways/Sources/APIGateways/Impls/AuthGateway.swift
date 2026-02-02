import Foundation
@preconcurrency import Shared

/// Adapter that wraps KMP AuthGatewayImpl and exposes it through Swift protocol
public struct AuthGatewayAdapter: AuthGatewayProtocol, @unchecked Sendable {
    private let kmpGateway: Shared.AuthGatewayImpl

    public init(kmpGateway: Shared.AuthGatewayImpl) {
        self.kmpGateway = kmpGateway
    }

    public func login(username: String, password: String) async throws -> Shared.TokenResponse {
        try await kmpGateway.login(username: username, password: password)
    }
}
