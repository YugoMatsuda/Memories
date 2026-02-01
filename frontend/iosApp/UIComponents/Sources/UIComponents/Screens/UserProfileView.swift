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

            Section {
                Button(role: .destructive) {
                    viewModel.showLogoutConfirmation()
                } label: {
                    Text("Logout")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
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
            ImagePicker(image: $viewModel.selectedImage, allowsEditing: true)
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
                avatarImage
            }
            .disabled(viewModel.isSaving)
            Spacer()
        }
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let selectedImage = viewModel.selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipped()
                .clipShape(Circle())
        } else if let url = viewModel.uiModel.avatarUrl {
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
