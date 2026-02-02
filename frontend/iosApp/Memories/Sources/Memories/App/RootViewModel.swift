import Foundation
import SwiftUI
import Combine
import UseCases
import UILogics

public enum RootViewState: Equatable {
    case launching
    case unauthenticated
    case authenticated(token: String, userId: Int, hasPreviousSession: Bool)
}

@MainActor
public final class RootViewModel: ObservableObject {
    @Published public private(set) var state: RootViewState = .launching
    @Published public var alertItem: AlertItem?

    // DeepLink
    private(set) var pendingDeepLink: UseCases.DeepLink?
    public let deepLinkSubject = PassthroughSubject<UseCases.DeepLink, Never>()

    private let rootUseCase: RootUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    public init(rootUseCase: RootUseCaseProtocol = AppConfig.rootUseCase) {
        self.rootUseCase = rootUseCase

        rootUseCase.observeDidLogout
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleLogout()
            }
            .store(in: &cancellables)
    }

    public func initialize() {
        let result = rootUseCase.checkPreviousSession()
        switch result {
        case .loggedIn(let session):
            state = .authenticated(token: session.token, userId: session.userIdInt, hasPreviousSession: true)
        case .notLoggedIn:
            state = .unauthenticated
        }
    }

    public func didLogin(token: String, userId: Int) {
        state = .authenticated(token: token, userId: userId, hasPreviousSession: false)
    }

    public func handleDeepLink(url: URL) {
        let result = rootUseCase.handleDeepLink(url: url)

        switch result {
        case .authenticated(let deepLink):
            if case .authenticated = state {
                // Warm Start: Router already exists
                deepLinkSubject.send(deepLink)
            } else {
                // Cold Start: Waiting for Container creation
                pendingDeepLink = deepLink
            }

        case .notAuthenticated(let deepLink):
            pendingDeepLink = deepLink
            alertItem = AlertItem(
                title: "Login Required",
                message: "Please log in to view this content.",
                buttons: [.default(Text("OK"))]
            )

        case .invalidURL:
            alertItem = AlertItem(
                title: "Invalid Link",
                message: "This link cannot be opened.",
                buttons: [.default(Text("OK"))]
            )
        }
    }

    public func consumePendingDeepLink() -> UseCases.DeepLink? {
        defer { pendingDeepLink = nil }
        return pendingDeepLink
    }

    private func handleLogout() {
        state = .unauthenticated
        pendingDeepLink = nil
    }
}
