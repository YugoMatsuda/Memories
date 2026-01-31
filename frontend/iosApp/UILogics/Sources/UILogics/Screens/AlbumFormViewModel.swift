import Foundation
import SwiftUI
import Domains

@MainActor
public final class AlbumFormViewModel: ObservableObject {
    @Published public var title: String
    @Published public var isSaving = false
    @Published public var alertItem: AlertItem?

    public let mode: AlbumFormMode
    private let onDismiss: () -> Void

    public var navigationTitle: String {
        switch mode {
        case .create:
            return "New Album"
        case .edit:
            return "Edit Album"
        }
    }

    public init(mode: AlbumFormMode, onDismiss: @escaping () -> Void) {
        self.mode = mode
        self.onDismiss = onDismiss

        switch mode {
        case .create:
            self.title = ""
        case .edit(let album):
            self.title = album.title
        }
    }

    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public func save() {
        Task {
            await saveAlbum()
        }
    }

    public func cancel() {
        onDismiss()
    }

    private func saveAlbum() async {
        isSaving = true
        // TODO: Implement save logic with UseCase
        try? await Task.sleep(nanoseconds: 500_000_000)
        isSaving = false
        onDismiss()
    }
}
