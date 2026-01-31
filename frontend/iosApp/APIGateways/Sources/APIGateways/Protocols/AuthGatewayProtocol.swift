import Foundation
import APIClients

public protocol AuthGatewayProtocol: Sendable {
    func login(username: String, password: String) async throws -> TokenResponse
}
