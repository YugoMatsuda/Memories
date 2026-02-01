import Foundation
import Domains

public protocol UserProfileUseCaseProtocol: Sendable {
    func updateProfile(name: String, birthday: Date?, avatarData: Data?) async -> UserProfileUseCaseModel.UpdateProfileResult
    func logout()
}

public enum UserProfileUseCaseModel {
    public enum UpdateProfileResult: Sendable {
        case success(User)
        case successPendingSync(User)
        case failure(Error)

        public enum Error: Sendable {
            case networkError
            case serverError
            case imageStorageFailed
            case databaseError
            case unknown
        }
    }
}
