import Foundation
import SwiftUI
import Combine
import Domains
import UseCases
@preconcurrency import Shared

@MainActor
public final class UserProfileViewModel: ObservableObject {
    @Published public var uiModel: UserProfileUIModel
    @Published public var selectedImage: UIImage? {
        didSet {
            if let image = selectedImage {
                pendingAvatarImage = image
            }
        }
    }
    @Published public var isShowingImagePicker = false
    @Published public var isSaving = false
    @Published public var alertItem: AlertItem?

    private var pendingAvatarImage: UIImage?
    private let useCase: UserProfileUseCaseProtocol

    public init(user: User, useCase: UserProfileUseCaseProtocol) {
        self.useCase = useCase
        self.uiModel = UserProfileUIModel(
            name: user.name,
            username: user.username,
            birthday: user.birthdayDate,
            avatarUrl: user.displayAvatarURL
        )
    }

    public func selectAvatar() {
        isShowingImagePicker = true
    }

    public func save() {
        Task {
            await saveProfile()
        }
    }

    public func showLogoutConfirmation() {
        alertItem = AlertItem(
            title: "Logout",
            message: "Are you sure you want to logout?",
            buttons: [
                Alert.Button.destructive(Text("Logout")) { [weak self] in
                    self?.useCase.logout()
                },
                Alert.Button.cancel()
            ]
        )
    }

    private func saveProfile() async {
        isSaving = true

        let avatarData: Data? = pendingAvatarImage?.jpegData(compressionQuality: 0.8)

        let result = await useCase.updateProfile(
            name: uiModel.name.trimmingCharacters(in: .whitespaces),
            birthday: uiModel.birthday,
            avatarData: avatarData
        )

        isSaving = false

        switch onEnum(of: result) {
        case .success(let success):
            uiModel.avatarUrl = success.user.displayAvatarURL
            pendingAvatarImage = nil
            selectedImage = nil
            alertItem = AlertItem(
                title: "Saved",
                message: "Your profile has been updated.",
                buttons: [Alert.Button.default(Text("OK"))]
            )
        case .successPendingSync(let pendingSync):
            uiModel.avatarUrl = pendingSync.user.displayAvatarURL
            pendingAvatarImage = nil
            selectedImage = nil
            alertItem = AlertItem(
                title: "Saved",
                message: "Your profile has been saved locally and will sync when online.",
                buttons: [Alert.Button.default(Text("OK"))]
            )
        case .failure(let failure):
            showAlert(for: failure.error)
        }
    }

    private func showAlert(for error: Shared.UpdateProfileError) {
        let message: String
        switch error {
        case .networkError:
            message = "Network error. Please check your connection and try again."
        case .serverError:
            message = "Server error. Please try again later."
        case .imageStorageFailed:
            message = "Failed to save the image locally. Please try again."
        case .databaseError:
            message = "Failed to save to local database. Please try again."
        default:
            message = "An unexpected error occurred. Please try again."
        }

        alertItem = AlertItem(
            title: "Save Failed",
            message: message,
            buttons: [Alert.Button.default(Text("OK"))]
        )
    }
}

// MARK: - UI Models

extension UserProfileViewModel {
    public struct UserProfileUIModel: Equatable {
        public var name: String
        public let username: String
        public var birthday: Date?
        public var avatarUrl: URL?

        public init(name: String, username: String, birthday: Date?, avatarUrl: URL?) {
            self.name = name
            self.username = username
            self.birthday = birthday
            self.avatarUrl = avatarUrl
        }
    }
}
