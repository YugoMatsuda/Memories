import Foundation
import SwiftUI
import Combine
import Domains
import UseCases

@MainActor
public final class UserProfileViewModel: ObservableObject {
    @Published public var uiModel: UserProfileUIModel
    @Published public var selectedImage: UIImage?
    @Published public var isShowingImagePicker = false
    @Published public var isUploadingAvatar = false
    @Published public var isSaving = false
    @Published public var alertItem: AlertItem?

    private let useCase: UserProfileUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    public init(user: User, useCase: UserProfileUseCaseProtocol) {
        self.useCase = useCase
        self.uiModel = UserProfileUIModel(
            name: user.name,
            username: user.username,
            birthday: user.birthday,
            avatarUrl: user.avatarUrl
        )

        subscribeToImageSelection()
    }

    public func selectAvatar() {
        isShowingImagePicker = true
    }

    public func save() {
        Task {
            await saveProfile()
        }
    }

    private func saveProfile() async {
        isSaving = true
        let result = await useCase.updateProfile(
            name: uiModel.name.trimmingCharacters(in: .whitespaces),
            birthday: uiModel.birthday
        )
        isSaving = false

        switch result {
        case .success:
            break
        case .failure(let error):
            showAlert(for: error)
        }
    }

    private func subscribeToImageSelection() {
        $selectedImage
            .compactMap { $0 }
            .sink { [weak self] image in
                Task { [weak self] in
                    await self?.uploadAvatar(image: image)
                }
            }
            .store(in: &cancellables)
    }

    private func uploadAvatar(image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showAlert(for: .invalidImageData)
            return
        }

        isUploadingAvatar = true
        let result = await useCase.uploadAvatar(imageData: imageData)
        isUploadingAvatar = false

        switch result {
        case .success(let updatedUser):
            uiModel.avatarUrl = updatedUser.avatarUrl
            selectedImage = nil
        case .failure(let error):
            showAlert(for: error)
        }
    }

    private func showAlert(for error: UserProfileUseCaseModel.UploadAvatarResult.Error) {
        let message: String
        switch error {
        case .networkError:
            message = "Network error. Please check your connection and try again."
        case .serverError:
            message = "Server error. Please try again later."
        case .unknown:
            message = "An unexpected error occurred. Please try again."
        }

        alertItem = AlertItem(
            title: "Upload Failed",
            message: message,
            buttons: [Alert.Button.default(Text("OK"))]
        )
    }

    private func showAlert(for error: UserProfileUseCaseModel.UpdateProfileResult.Error) {
        let message: String
        switch error {
        case .networkError:
            message = "Network error. Please check your connection and try again."
        case .serverError:
            message = "Server error. Please try again later."
        case .unknown:
            message = "An unexpected error occurred. Please try again."
        }

        alertItem = AlertItem(
            title: "Save Failed",
            message: message,
            buttons: [Alert.Button.default(Text("OK"))]
        )
    }

    private func showAlert(for error: ImageDataError) {
        alertItem = AlertItem(
            title: "Error",
            message: "Failed to process the selected image.",
            buttons: [Alert.Button.default(Text("OK"))]
        )
    }

    private enum ImageDataError {
        case invalidImageData
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
