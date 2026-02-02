import Foundation
import Domains
@preconcurrency import Shared

// MARK: - Protocol

public protocol UserProfileUseCaseProtocol: Sendable {
    func updateProfile(name: String, birthday: Date?, avatarData: Data?) async -> Shared.UpdateProfileResult
    func logout()
}

// MARK: - Adapter

public final class UserProfileUseCaseAdapter: UserProfileUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.UserProfileUseCase

    public init(kmpUseCase: Shared.UserProfileUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func updateProfile(name: String, birthday: Date?, avatarData: Data?) async -> Shared.UpdateProfileResult {
        do {
            let kotlinBirthday = birthday.map { Kotlinx_datetimeLocalDate.from(date: $0) }
            let imageBytes = avatarData.map { KotlinByteArray(data: $0) }
            return try await kmpUseCase.updateProfile(name: name, birthday: kotlinBirthday, avatarData: imageBytes)
        } catch {
            return Shared.UpdateProfileResult.Failure(error: .unknown)
        }
    }

    public func logout() {
        kmpUseCase.logout()
    }
}
