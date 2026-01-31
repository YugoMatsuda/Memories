import Foundation
import Domains
import APIGateways
import APIClients
import Repositories
import Utilities

public struct UserProfileUseCase: UserProfileUseCaseProtocol, Sendable {
    private let userGateway: UserGatewayProtocol
    private let userRepository: UserRepositoryProtocol

    public init(userGateway: UserGatewayProtocol, userRepository: UserRepositoryProtocol) {
        self.userGateway = userGateway
        self.userRepository = userRepository
    }

    public func uploadAvatar(imageData: Data) async -> UserProfileUseCaseModel.UploadAvatarResult {
        let fileName = "\(UUID().uuidString).jpg"
        let mimeType = "image/jpeg"

        do {
            let response = try await userGateway.uploadAvatar(
                fileData: imageData,
                fileName: fileName,
                mimeType: mimeType
            )
            let user = UserMapper.toDomain(response)
            userRepository.set(user)
            return .success(user)
        } catch let error as APIError {
            return .failure(mapAvatarError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    public func updateProfile(name: String, birthday: Date?) async -> UserProfileUseCaseModel.UpdateProfileResult {
        let birthdayString = birthday.map { DateFormatters.yyyyMMdd.string(from: $0) }

        do {
            let response = try await userGateway.updateUser(
                name: name,
                birthday: birthdayString,
                avatarUrl: nil
            )
            let user = UserMapper.toDomain(response)
            userRepository.set(user)
            return .success(user)
        } catch let error as APIError {
            return .failure(mapProfileError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    private func mapAvatarError(_ error: APIError) -> UserProfileUseCaseModel.UploadAvatarResult.Error {
        switch error {
        case .networkError, .timeout:
            return .networkError
        case .serverError, .serviceUnavailable:
            return .serverError
        default:
            return .unknown
        }
    }

    private func mapProfileError(_ error: APIError) -> UserProfileUseCaseModel.UpdateProfileResult.Error {
        switch error {
        case .networkError, .timeout:
            return .networkError
        case .serverError, .serviceUnavailable:
            return .serverError
        default:
            return .unknown
        }
    }
}
