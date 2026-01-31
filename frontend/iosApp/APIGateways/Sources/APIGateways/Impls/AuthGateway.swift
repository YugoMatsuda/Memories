import Foundation
import APIClients

public struct AuthGateway: AuthGatewayProtocol {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func login(username: String, password: String) async throws -> TokenResponse {
        let request = LoginRequest(username: username, password: password)
        let data = try await apiClient.send(request)
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
}
