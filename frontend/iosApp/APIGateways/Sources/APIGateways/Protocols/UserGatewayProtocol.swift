import Foundation
@preconcurrency import Shared

public protocol UserGatewayProtocol: Sendable {
    func getUser() async throws -> Shared.UserResponse
    func updateUser(name: String?, birthday: String?, avatarUrl: String?) async throws -> Shared.UserResponse
    func uploadAvatar(fileData: Data, fileName: String, mimeType: String) async throws -> Shared.UserResponse
}
