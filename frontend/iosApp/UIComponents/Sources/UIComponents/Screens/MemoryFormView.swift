import SwiftUI
import UILogics

public struct MemoryFormView: View {
    @ObservedObject var viewModel: MemoryFormViewModel

    public init(viewModel: MemoryFormViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    imageSection
                } header: {
                    Text("Photo")
                }

                Section {
                    TextField("Memory Title", text: $viewModel.title)
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
                ImagePicker(image: $viewModel.selectedImage, allowsEditing: false)
            }
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        Button {
            viewModel.selectImage()
        } label: {
            HStack {
                Spacer()
                imageView
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var imageView: some View {
        Group {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
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
                Text("Add Photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
