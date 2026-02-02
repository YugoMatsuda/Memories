import Foundation
import APIGateways
import Repositories
import UseCases
@preconcurrency import Shared

public enum OnlineState: Sendable {
    case debug(initialState: Bool)
    case production
}

public enum AppConfig {
    public static let baseURL = URL(string: "http://localhost:8000")!
    // .debug(initialState: true)  - Debug mode, starts online
    // .debug(initialState: false) - Debug mode, starts offline
    // .production                 - Production mode, uses actual network state
    public static let onlineState: OnlineState = .debug(initialState: true)

    public static let reachabilityRepository: ReachabilityRepositoryProtocol = {
        switch onlineState {
        case .debug(let initialState):
            return DebugReachabilityRepository(isOnline: initialState)
        case .production:
            return ReachabilityRepository()
        }
    }()

    // Shared instances - KMP API Client
    public static let kmpPublicApiClient = Shared.PublicApiClient(baseUrl: baseURL.absoluteString)
    public static let kmpAuthGateway = Shared.AuthGatewayImpl(apiClient: kmpPublicApiClient)
    public static let authGateway: AuthGatewayProtocol = AuthGatewayAdapter(kmpGateway: kmpAuthGateway)
    public static let authSessionRepository = AuthSessionRepository()

    public static let rootUseCase = RootUseCase(authSessionRepository: authSessionRepository)
    public static let loginUseCase = LoginUseCase(
        authGateway: authGateway,
        authSessionRepository: authSessionRepository
    )
}
