import Foundation
import APIClients

public struct UserGateway: UserGatewayProtocol {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func getUser() async throws -> UserResponse {
        let request = GetUserRequest()
        let data = try await apiClient.send(request)
        return try JSONDecoder().decode(UserResponse.self, from: data)
    }

    public func updateUser(name: String?, birthday: String?, avatarUrl: String?) async throws -> UserResponse {
        let request = UserUpdateRequest(name: name, birthday: birthday, avatarUrl: avatarUrl)
        let data = try await apiClient.send(request)
        return try JSONDecoder().decode(UserResponse.self, from: data)
    }

    public func uploadAvatar(fileData: Data, fileName: String, mimeType: String) async throws -> UserResponse {
        let request = AvatarUploadRequest(fileData: fileData, fileName: fileName, mimeType: mimeType)
        let data = try await apiClient.send(request)
        return try JSONDecoder().decode(UserResponse.self, from: data)
    }
}
