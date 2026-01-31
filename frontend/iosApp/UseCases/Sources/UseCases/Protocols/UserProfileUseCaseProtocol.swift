import Foundation
import Domains

public protocol UserProfileUseCaseProtocol: Sendable {
    func uploadAvatar(imageData: Data) async -> UserProfileUseCaseModel.UploadAvatarResult
    func updateProfile(name: String, birthday: Date?) async -> UserProfileUseCaseModel.UpdateProfileResult
}

public enum UserProfileUseCaseModel {
    public enum UploadAvatarResult: Sendable {
        case success(User)
        case failure(Error)

        public enum Error: Sendable {
            case networkError
            case serverError
            case unknown
        }
    }

    public enum UpdateProfileResult: Sendable {
        case success(User)
        case failure(Error)

        public enum Error: Sendable {
            case networkError
            case serverError
            case unknown
        }
    }
}
