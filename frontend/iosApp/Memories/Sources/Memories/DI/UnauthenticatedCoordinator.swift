import Foundation
import SwiftUI
import Domains
import UILogics
import UIComponents

@MainActor
public final class UnauthenticatedCoordinator: ObservableObject {
    private let factory: UnauthenticatedViewModelFactory
    private let onLogin: (String) -> Void

    public init(
        factory: UnauthenticatedViewModelFactory,
        onLogin: @escaping (String) -> Void
    ) {
        self.factory = factory
        self.onLogin = onLogin
    }

    public func makeLoginView() -> LoginView {
        let viewModel = factory.makeLoginViewModel(
            onSuccess: { [weak self] session in
                self?.onLogin(session.token)
            }
        )
        return LoginView(viewModel: viewModel)
    }

}
