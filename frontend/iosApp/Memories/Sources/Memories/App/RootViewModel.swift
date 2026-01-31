import Foundation
import SwiftUI
import Combine
import Domains
import UseCases

public enum RootViewState: Equatable {
    case launching
    case unauthenticated
    case authenticated(token: String, hasPreviousSession: Bool)
}

@MainActor
public final class RootViewModel: ObservableObject {
    @Published public private(set) var state: RootViewState = .launching

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
            state = .authenticated(token: session.token, hasPreviousSession: true)
        case .notLoggedIn:
            state = .unauthenticated
        }
    }

    public func didLogin(token: String) {
        AppConfig.authSessionRepository.save(session: AuthSession(token: token))
        state = .authenticated(token: token, hasPreviousSession: false)
    }

    private func handleLogout() {
        state = .unauthenticated
    }
}
