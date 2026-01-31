import SwiftUI
import UIComponents

public struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    public init(viewModel: RootViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .launching:
                ProgressView()

            case .unauthenticated:
                UnauthenticatedRootView(
                    onLogin: { token in
                        viewModel.didLogin(token: token)
                    }
                )

            case .authenticated(let token, let hasPreviousSession):
                AuthenticatedRootView(token: token, hasPreviousSession: hasPreviousSession)
            }
        }
        .animation(.default, value: viewModel.state)
        .transition(.opacity)
    }
}

struct UnauthenticatedRootView: View {
    let onLogin: (String) -> Void

    @StateObject private var coordinator: UnauthenticatedCoordinator

    init(onLogin: @escaping (String) -> Void) {
        self.onLogin = onLogin
        _coordinator = StateObject(wrappedValue: UnauthenticatedCoordinator(
            factory: UnauthenticatedViewModelFactory(),
            onLogin: onLogin
        ))
    }

    var body: some View {
        coordinator.makeLoginView()
    }
}

struct AuthenticatedRootView: View {
    @StateObject private var coordinator: AuthenticatedCoordinator
    @StateObject private var router: AuthenticatedRouter

    init(token: String, hasPreviousSession: Bool) {
        let container = AuthenticatedContainer(token: token)
        let factory = AuthenticatedViewModelFactory(container: container)
        let coordinator = AuthenticatedCoordinator(
            factory: factory,
            hasPreviousSession: hasPreviousSession
        )
        _coordinator = StateObject(wrappedValue: coordinator)
        _router = StateObject(wrappedValue: container.router)
    }

    var body: some View {
        Group {
            switch coordinator.state {
            case .splash:
                coordinator.makeSplashView()

            case .continueAs(let user):
                coordinator.makeLoginView(user: user)

            case .main:
                NavigationStack(path: $router.path) {
                    coordinator.makeAlbumListView()
                        .navigationDestination(for: AuthenticatedRoute.self) { route in
                            coordinator.destination(for: route)
                        }
                }
            }
        }
        .animation(.default, value: coordinator.state)
        .transition(.opacity)
    }
}
