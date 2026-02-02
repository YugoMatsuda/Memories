import Foundation
import SwiftUI
import Domains
import UseCases
@preconcurrency import Shared

@MainActor
public final class MemoryFormViewModel: ObservableObject {
    @Published public var title: String = ""
    @Published public var selectedImage: UIImage?
    @Published public var isShowingImagePicker = false
    @Published public var isSaving = false
    @Published public var alertItem: AlertItem?

    private let album: Album
    private let useCase: MemoryFormUseCaseProtocol
    private let router: AuthenticatedRouterProtocol

    public var navigationTitle: String { "New Memory" }

    public init(album: Album, useCase: MemoryFormUseCaseProtocol, router: AuthenticatedRouterProtocol) {
        self.album = album
        self.useCase = useCase
        self.router = router
    }

    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && selectedImage != nil
    }

    public func selectImage() {
        isShowingImagePicker = true
    }

    public func save() {
        Task {
            await saveMemory()
        }
    }

    public func cancel() {
        router.dismissSheet()
    }

    private func saveMemory() async {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        isSaving = true
        let result = await useCase.createMemory(
            album: album,
            title: title.trimmingCharacters(in: .whitespaces),
            imageData: imageData
        )
        isSaving = false

        switch onEnum(of: result) {
        case .success, .successPendingSync:
            router.dismissSheet()
        case .failure(let failure):
            showAlert(for: failure.error)
        }
    }

    private func showAlert(for error: Shared.MemoryCreateError) {
        let message: String
        switch error {
        case .networkError:
            message = "Network error. Please check your connection and try again."
        case .imageStorageFailed:
            message = "Failed to save image. Please try again."
        case .databaseError:
            message = "Failed to save memory. Please try again."
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
