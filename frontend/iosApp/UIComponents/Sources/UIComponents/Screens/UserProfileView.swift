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
                TextField("Name", text: $viewModel.name)

                HStack {
                    Text("Username")
                    Spacer()
                    Text(viewModel.username)
                        .foregroundStyle(.secondary)
                }

                OptionalDatePicker(
                    "Birthday",
                    prompt: "Not set",
                    selection: $viewModel.birthday
                )
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    viewModel.save()
                }
                .disabled(viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(isPresented: $viewModel.isShowingImagePicker) {
            CropableImagePicker(image: $viewModel.selectedImage)
        }
    }

    @ViewBuilder
    private var avatarSection: some View {
        HStack {
            Spacer()
            Button {
                viewModel.selectAvatar()
            } label: {
                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else if let avatarUrl = viewModel.avatarUrl {
                    WebImage(url: avatarUrl)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
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
            Spacer()
        }
    }
}
