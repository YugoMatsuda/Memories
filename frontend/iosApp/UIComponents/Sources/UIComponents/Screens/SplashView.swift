import SwiftUI
import UILogics

public struct SplashView: View {
    @StateObject private var viewModel: SplashViewModel

    public init(viewModel: SplashViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 16) {
            switch viewModel.state {
            case .initial:
                EmptyView()

            case .loading(let message):
                loadingView(message: message)

            case .error(let item):
                errorView(item: item)
            }
        }
        .task {
            await viewModel.launchApp()
        }
    }

    @ViewBuilder
    private func loadingView(message: String) -> some View {
        ProgressView()
        Text(message)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    @ViewBuilder
    private func errorView(item: SplashViewModel.State.ErrorItem) -> some View {
        Image(systemName: item.icon)
            .font(.largeTitle)
            .foregroundColor(item.iconColor.color)

        Text(item.message)
            .font(.body)
            .multilineTextAlignment(.center)

        Button(item.buttonTitle) {
            item.action()
        }
        .buttonStyle(.borderedProminent)
    }
}

extension SplashViewModel.State.ErrorItem.IconColor {
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        }
    }
}
