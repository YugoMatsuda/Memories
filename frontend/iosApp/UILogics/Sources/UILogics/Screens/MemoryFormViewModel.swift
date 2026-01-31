import Foundation
import SwiftUI
import Domains
import UseCases

@MainActor
public final class MemoryFormViewModel: ObservableObject {
    @Published public var title: String = ""
    @Published public var selectedImage: UIImage?
    @Published public var isShowingImagePicker = false
    @Published public var isSaving = false
    @Published public var alertItem: AlertItem?

    private let albumId: Int
    private let useCase: MemoryFormUseCaseProtocol
    private let router: AuthenticatedRouterProtocol

    public var navigationTitle: String { "New Memory" }

    public init(albumId: Int, useCase: MemoryFormUseCaseProtocol, router: AuthenticatedRouterProtocol) {
        self.albumId = albumId
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
            albumId: albumId,
            title: title.trimmingCharacters(in: .whitespaces),
            imageData: imageData
        )
        isSaving = false

        switch result {
        case .success:
            router.dismissSheet()
        case .failure(let error):
            showAlert(for: error)
        }
    }

    private func showAlert(for error: MemoryFormUseCaseModel.CreateResult.Error) {
        let message: String
        switch error {
        case .networkError:
            message = "Network error. Please check your connection and try again."
        case .unknown:
            message = "An unexpected error occurred. Please try again."
        }

        alertItem = AlertItem(
            title: "Save Failed",
            message: message,
            buttons: [Alert.Button.default(Text("OK"))]
        )
    }
}
