import Foundation
import Domains
import UseCases

@MainActor
public final class SplashViewModel: ObservableObject {
    @Published public var state: State = .initial

    private let splashUseCase: SplashUseCaseProtocol
    private let onSuccess: (User) -> Void

    public init(
        splashUseCase: SplashUseCaseProtocol,
        onSuccess: @escaping (User) -> Void
    ) {
        self.splashUseCase = splashUseCase
        self.onSuccess = onSuccess
    }

    public func launchApp() async {
        state = .loading(message: "Loading user data...")

        let result = await splashUseCase.launchApp()

        switch result {
        case .success(let user):
            onSuccess(user)
        case .failure(let error):
            handleError(error)
        }
    }

    private func handleError(_ error: SplashUseCaseModel.LaunchAppResult.Error) {
        switch error {
        case .sessionExpired:
            state = .error(.init(
                icon: "clock.badge.exclamationmark",
                iconColor: .red,
                message: "Session has expired",
                buttonTitle: "Go to Login",
                action: { [weak self] in
                    self?.splashUseCase.clearSession()
                }
            ))
        case .networkError:
            state = .error(.init(
                icon: "exclamationmark.triangle",
                iconColor: .orange,
                message: "Network error occurred",
                buttonTitle: "Retry",
                action: { [weak self] in
                    Task { await self?.launchApp() }
                }
            ))
        case .offlineNoCache:
            state = .error(.init(
                icon: "wifi.slash",
                iconColor: .orange,
                message: "You're offline with no cached data",
                buttonTitle: "Retry",
                action: { [weak self] in
                    Task { await self?.launchApp() }
                }
            ))
        case .serverError:
            state = .error(.init(
                icon: "exclamationmark.triangle",
                iconColor: .orange,
                message: "Server error occurred",
                buttonTitle: "Retry",
                action: { [weak self] in
                    Task { await self?.launchApp() }
                }
            ))
        case .unknown:
            state = .error(.init(
                icon: "exclamationmark.triangle",
                iconColor: .orange,
                message: "Unknown error occurred",
                buttonTitle: "Retry",
                action: { [weak self] in
                    Task { await self?.launchApp() }
                }
            ))
        }
    }
}

extension SplashViewModel {
    public enum State {
        case initial
        case loading(message: String)
        case error(ErrorItem)

        public struct ErrorItem {
            public let icon: String
            public let iconColor: IconColor
            public let message: String
            public let buttonTitle: String
            public let action: () -> Void

            public enum IconColor {
                case red
                case orange
            }
        }
    }
}
