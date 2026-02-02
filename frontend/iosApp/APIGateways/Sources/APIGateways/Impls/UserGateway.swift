import Foundation
import Domains
@preconcurrency import Shared

/// Adapter that wraps KMP UserGatewayImpl and exposes it through Swift protocol
public struct UserGatewayAdapter: UserGatewayProtocol, @unchecked Sendable {
    private let kmpGateway: Shared.UserGatewayImpl

    public init(kmpGateway: Shared.UserGatewayImpl) {
        self.kmpGateway = kmpGateway
    }

    public func getUser() async throws -> Shared.UserResponse {
        try await kmpGateway.getUser()
    }

    public func updateUser(name: String?, birthday: String?, avatarUrl: String?) async throws -> Shared.UserResponse {
        try await kmpGateway.updateUser(name: name, birthday: birthday, avatarUrl: avatarUrl)
    }

    public func uploadAvatar(fileData: Data, fileName: String, mimeType: String) async throws -> Shared.UserResponse {
        try await kmpGateway.uploadAvatar(
            fileData: KotlinByteArray.from(data: fileData),
            fileName: fileName,
            mimeType: mimeType
        )
    }
}
