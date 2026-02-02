import Foundation
import SwiftUI
import Combine
import UseCases
import UILogics
@preconcurrency import Shared

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
    private(set) var pendingDeepLink: Shared.DeepLink?
    public let deepLinkSubject = PassthroughSubject<Shared.DeepLink, Never>()

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
        switch onEnum(of: result) {
        case .loggedIn(let loggedIn):
            state = .authenticated(token: loggedIn.session.token, userId: Int(loggedIn.session.userId), hasPreviousSession: true)
        case .notLoggedIn:
            state = .unauthenticated
        }
    }

    public func didLogin(token: String, userId: Int) {
        state = .authenticated(token: token, userId: userId, hasPreviousSession: false)
    }

    public func handleDeepLink(url: URL) {
        let result = rootUseCase.handleDeepLink(url: url)

        switch onEnum(of: result) {
        case .authenticated(let authenticated):
            if case .authenticated = state {
                // Warm Start: Router already exists
                deepLinkSubject.send(authenticated.deepLink)
            } else {
                // Cold Start: Waiting for Container creation
                pendingDeepLink = authenticated.deepLink
            }
        case .notAuthenticated(let notAuthenticated):
            pendingDeepLink = notAuthenticated.deepLink
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

    public func consumePendingDeepLink() -> Shared.DeepLink? {
        defer { pendingDeepLink = nil }
        return pendingDeepLink
    }

    private func handleLogout() {
        state = .unauthenticated
        pendingDeepLink = nil
    }
}
