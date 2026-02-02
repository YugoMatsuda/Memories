import Foundation
import Domains
@preconcurrency import Shared

/// Adapter that wraps KMP UserProfileUseCase to conform to Swift UserProfileUseCaseProtocol
public final class UserProfileUseCaseAdapter: UserProfileUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.UserProfileUseCase

    public init(kmpUseCase: Shared.UserProfileUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func updateProfile(name: String, birthday: Date?, avatarData: Data?) async -> UserProfileUseCaseModel.UpdateProfileResult {
        do {
            let kotlinBirthday = birthday.map { date -> Kotlinx_datetimeLocalDate in
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                return Kotlinx_datetimeLocalDate(
                    year: Int32(components.year ?? 1970),
                    monthNumber: Int32(components.month ?? 1),
                    dayOfMonth: Int32(components.day ?? 1)
                )
            }
            let imageBytes = avatarData.map { KotlinByteArray(data: $0) }
            let result = try await kmpUseCase.updateProfile(name: name, birthday: kotlinBirthday, avatarData: imageBytes)

            if let success = result as? Shared.UpdateProfileResult.Success {
                return .success(success.user)
            } else if let pendingSync = result as? Shared.UpdateProfileResult.SuccessPendingSync {
                return .successPendingSync(pendingSync.user)
            } else if let failure = result as? Shared.UpdateProfileResult.Failure {
                return .failure(mapError(failure.error))
            }
            return .failure(.unknown)
        } catch {
            return .failure(.unknown)
        }
    }

    public func logout() {
        kmpUseCase.logout()
    }

    private func mapError(_ error: Shared.UpdateProfileError) -> UserProfileUseCaseModel.UpdateProfileResult.Error {
        switch error {
        case .networkError: return .networkError
        case .serverError: return .serverError
        case .imageStorageFailed: return .imageStorageFailed
        case .databaseError: return .databaseError
        default: return .unknown
        }
    }
}
