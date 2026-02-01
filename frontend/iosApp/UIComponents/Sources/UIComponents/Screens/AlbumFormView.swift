import SwiftUI
import UILogics
import SDWebImageSwiftUI

public struct AlbumFormView: View {
    @ObservedObject var viewModel: AlbumFormViewModel

    public init(viewModel: AlbumFormViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    coverImageSection
                } header: {
                    Text("Cover Image")
                }

                Section {
                    TextField("Album Title", text: $viewModel.title)
                } header: {
                    Text("Title")
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
            .sheet(isPresented: $viewModel.isShowingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage, allowsEditing: true)
            }
        }
    }

    @ViewBuilder
    private var coverImageSection: some View {
        Button {
            viewModel.selectCoverImage()
        } label: {
            HStack {
                Spacer()
                coverImageView
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var coverImageView: some View {
        Group {
            switch viewModel.coverImage {
            case .selectedImage(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            case .uploadedImage(let url):
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
            case .none:
                placeholderView
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    private var placeholderView: some View {
        ZStack {
            Color.secondary.opacity(0.1)
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.plus")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("Add Cover")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
