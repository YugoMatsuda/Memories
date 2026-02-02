import Foundation
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
    public static let authSessionRepository = AuthSessionRepository()

    // KMP AuthSessionRepository Bridge
    private static let authSessionRepositoryBridge = AuthSessionRepositoryBridgeImpl(repository: authSessionRepository)
    private static let kmpAuthSessionRepository = Shared.AuthSessionRepositoryImpl(bridge: authSessionRepositoryBridge)

    // KMP UseCases
    public static let rootUseCase: RootUseCaseProtocol = {
        let kmpUseCase = Shared.RootUseCaseImpl(authSessionRepository: kmpAuthSessionRepository)
        return RootUseCaseAdapter(kmpUseCase: kmpUseCase)
    }()

    public static let loginUseCase: LoginUseCaseProtocol = {
        let kmpUseCase = Shared.LoginUseCaseImpl(
            authGateway: kmpAuthGateway,
            authSessionRepository: kmpAuthSessionRepository
        )
        return LoginUseCaseAdapter(kmpUseCase: kmpUseCase)
    }()
}
