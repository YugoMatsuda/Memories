import SwiftUI
import UILogics

public struct AlbumFormView: View {
    @ObservedObject var viewModel: AlbumFormViewModel

    public init(viewModel: AlbumFormViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Album Title", text: $viewModel.title)
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            viewModel.save()
                        }
                        .disabled(!viewModel.isValid)
                    }
                }
            }
            .showAlert(item: $viewModel.alertItem)
        }
    }
}
