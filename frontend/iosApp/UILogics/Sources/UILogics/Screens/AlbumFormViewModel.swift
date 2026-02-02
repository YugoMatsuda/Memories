import Foundation
import SwiftUI
import Domains
import UseCases

@MainActor
public final class AlbumFormViewModel: ObservableObject {
    @Published public var title: String
    @Published public var coverImage: ImageUIModel?
    @Published public var selectedImage: UIImage? {
        didSet {
            if let image = selectedImage {
                coverImage = .selectedImage(image)
            }
        }
    }
    @Published public var isShowingImagePicker = false
    @Published public var isSaving = false
    @Published public var alertItem: AlertItem?

    public let mode: AlbumFormMode
    private let useCase: AlbumFormUseCaseProtocol
    private let router: AuthenticatedRouterProtocol

    public var navigationTitle: String {
        switch mode {
        case .create:
            return "New Album"
        case .edit:
            return "Edit Album"
        }
    }

    public init(mode: AlbumFormMode, useCase: AlbumFormUseCaseProtocol, router: AuthenticatedRouterProtocol) {
        self.mode = mode
        self.useCase = useCase
        self.router = router

        switch mode {
        case .create:
            self.title = ""
            self.coverImage = nil
        case .edit(let album):
            self.title = album.title
            self.coverImage = album.displayCoverImageURL.map { .uploadedImage($0) }
        }
    }

    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public func selectCoverImage() {
        isShowingImagePicker = true
    }

    public func save() {
        Task {
            await saveAlbum()
        }
    }

    public func cancel() {
        router.dismissSheet()
    }

    private func saveAlbum() async {
        isSaving = true

        let imageData: Data? = {
            guard case .selectedImage(let image) = coverImage else {
                return nil
            }
            return image.jpegData(compressionQuality: 0.8)
        }()

        switch mode {
        case .create:
            await createAlbum(imageData: imageData)
        case .edit(let album):
            await updateAlbum(album: album, imageData: imageData)
        }

        isSaving = false
    }

    private func createAlbum(imageData: Data?) async {
        let result = await useCase.createAlbum(
            title: title.trimmingCharacters(in: .whitespaces),
            coverImageData: imageData
        )

        switch result {
        case .success, .successPendingSync:
            router.dismissSheet()
        case .failure(let error):
            showAlert(for: error)
        }
    }

    private func updateAlbum(album: Album, imageData: Data?) async {
        let result = await useCase.updateAlbum(
            album: album,
            title: title.trimmingCharacters(in: .whitespaces),
            coverImageData: imageData
        )

        switch result {
        case .success, .successPendingSync:
            router.dismissSheet()
        case .failure(let error):
            showAlert(for: error)
        }
    }

    private func showAlert(for error: AlbumFormUseCaseModel.CreateResult.Error) {
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
        case .unknown:
            message = "An unexpected error occurred. Please try again."
        }

        alertItem = AlertItem(
            title: "Save Failed",
            message: message,
            buttons: [Alert.Button.default(Text("OK"))]
        )
    }

    private func showAlert(for error: AlbumFormUseCaseModel.UpdateResult.Error) {
        let message: String
        switch error {
        case .networkError:
            message = "Network error. Please check your connection and try again."
        case .serverError:
            message = "Server error. Please try again later."
        case .notFound:
            message = "Album not found. It may have been deleted."
        case .imageStorageFailed:
            message = "Failed to save the image locally. Please try again."
        case .databaseError:
            message = "Failed to save to local database. Please try again."
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

// MARK: - UI Models

extension AlbumFormViewModel {
    public enum ImageUIModel: Equatable {
        case uploadedImage(URL)
        case selectedImage(UIImage)

        public var uploadedImageUrl: URL? {
            guard case let .uploadedImage(url) = self else {
                return nil
            }
            return url
        }

        public static func == (lhs: ImageUIModel, rhs: ImageUIModel) -> Bool {
            switch (lhs, rhs) {
            case (.uploadedImage(let lhsUrl), .uploadedImage(let rhsUrl)):
                return lhsUrl == rhsUrl
            case (.selectedImage(let lhsImage), .selectedImage(let rhsImage)):
                return lhsImage === rhsImage
            default:
                return false
            }
        }
    }
}
