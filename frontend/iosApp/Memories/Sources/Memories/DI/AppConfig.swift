import Foundation
import APIClients
import APIGateways
import Repositories
import UseCases

public enum OnlineState: Sendable {
    case debug(initialState: Bool)
    case production
}

public enum AppConfig {
    public static let baseURL = URL(string: "http://localhost:8000")!
    // .debug(initialState: true)  - Debug mode, starts online
    // .debug(initialState: false) - Debug mode, starts offline
    // .production                 - Production mode, uses actual network state
    public static let onlineState: OnlineState = .debug(initialState: false)

    public static let reachabilityRepository: ReachabilityRepositoryProtocol = {
        switch onlineState {
        case .debug(let initialState):
            return DebugReachabilityRepository(isOnline: initialState)
        case .production:
            return ReachabilityRepository()
        }
    }()

    // Shared instances
    public static let publicAPIClient = PublicAPIClient(baseURL: baseURL)
    public static let authGateway = AuthGateway(apiClient: publicAPIClient)
    public static let authSessionRepository = AuthSessionRepository()

    public static let rootUseCase = RootUseCase(authSessionRepository: authSessionRepository)
    public static let loginUseCase = LoginUseCase(
        authGateway: authGateway,
        authSessionRepository: authSessionRepository
    )
}
