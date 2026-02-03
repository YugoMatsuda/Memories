import SwiftUI
import UILogics

public struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    public init(viewModel: LoginViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 24) {
            
            Text("Memories")
                .font(.title)
            
            if let item = viewModel.continueAsItem {
                continueAsUserButton(item: item)
            }

            loginForm()

            if case .error(let message) = viewModel.loginState {
                Text(message)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .disabled(viewModel.loginState.isLoading)
        .overlay {
            if viewModel.loginState.isLoading {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private func continueAsUserButton(item: LoginViewModel.ContinueAsUIModel) -> some View {
        Button {
            item.onTap()
        } label: {
            HStack {
                AsyncImage(url: item.avatarUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                Text("Continue as \(item.userName)")
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func loginForm() -> some View {
        VStack(spacing: 16) {
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)

            Button("Login") {
                Task {
                    await viewModel.login()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
