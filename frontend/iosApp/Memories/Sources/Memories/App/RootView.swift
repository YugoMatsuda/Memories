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
                    onLogin: { token, userId in
                        viewModel.didLogin(token: token, userId: userId)
                    }
                )

            case .authenticated(let token, let userId, let hasPreviousSession):
                AuthenticatedRootView(token: token, userId: userId, hasPreviousSession: hasPreviousSession)
            }
        }
        .animation(.default, value: viewModel.state)
        .transition(.opacity)
    }
}

struct UnauthenticatedRootView: View {
    let onLogin: (String, Int) -> Void

    @StateObject private var coordinator: UnauthenticatedCoordinator

    init(onLogin: @escaping (String, Int) -> Void) {
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

    init(token: String, userId: Int, hasPreviousSession: Bool) {
        let container = AuthenticatedContainer(token: token, userId: userId)
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
                .sheet(item: $router.sheetItem) { sheet in
                    coordinator.sheetDestination(for: sheet)
                }
            }
        }
        .animation(.default, value: coordinator.state)
        .transition(.opacity)
    }
}
