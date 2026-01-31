import SwiftUI
import UILogics
import SDWebImageSwiftUI

public struct UserProfileView: View {
    @ObservedObject var viewModel: UserProfileViewModel

    public init(viewModel: UserProfileViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section {
                avatarSection
            }

            Section {
                TextField("Name", text: $viewModel.uiModel.name)

                HStack {
                    Text("Username")
                    Spacer()
                    Text(viewModel.uiModel.username)
                        .foregroundStyle(.secondary)
                }

                OptionalDatePicker(
                    "Birthday",
                    prompt: "Not set",
                    selection: $viewModel.uiModel.birthday
                )
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Save") {
                        viewModel.save()
                    }
                    .disabled(viewModel.uiModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingImagePicker) {
            CropableImagePicker(image: $viewModel.selectedImage)
        }
        .showAlert(item: $viewModel.alertItem)
    }

    @ViewBuilder
    private var avatarSection: some View {
        HStack {
            Spacer()
            Button {
                viewModel.selectAvatar()
            } label: {
                ZStack {
                    avatarImage

                    if viewModel.isUploadingAvatar {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 100, height: 100)
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .disabled(viewModel.isUploadingAvatar)
            Spacer()
        }
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let url = viewModel.uiModel.avatarUrl {
            WebImage(url: url)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipped()
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                }
        }
    }
}
