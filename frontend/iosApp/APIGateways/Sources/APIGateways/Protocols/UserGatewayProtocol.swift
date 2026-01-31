import Foundation
import APIClients

public protocol UserGatewayProtocol: Sendable {
    init(apiClient: any APIClientProtocol)
    func getUser() async throws -> UserResponse
    func updateUser(name: String?, birthday: String?, avatarUrl: String?) async throws -> UserResponse
    func uploadAvatar(fileData: Data, fileName: String, mimeType: String) async throws -> UserResponse
}
