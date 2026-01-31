import Foundation
import APIClients
import APIGateways
import Domains
import Repositories
import UseCases

@MainActor
public final class AuthenticatedContainer {
    private let token: String

    public init(token: String) {
        self.token = token
    }

    private lazy var apiClient: AuthenticatedAPIClient = {
        AuthenticatedAPIClient(apiToken: token, baseURL: AppConfig.baseURL)
    }()

    private lazy var userGateway: UserGateway = {
        UserGateway(apiClient: apiClient)
    }()

    private lazy var albumGateway: AlbumGateway = {
        AlbumGateway(apiClient: apiClient)
    }()

    private lazy var memoryGateway: MemoryGateway = {
        MemoryGateway(apiClient: apiClient)
    }()

    private lazy var userRepository: UserRepository = {
        UserRepository()
    }()

    public lazy var splashUseCase: SplashUseCase = {
        SplashUseCase(
            userGateway: userGateway,
            userRepository: userRepository,
            authSessionRepository: AppConfig.authSessionRepository
        )
    }()

    public let router = AuthenticatedRouter()

    public lazy var albumListUseCase: AlbumListUseCase = {
        AlbumListUseCase(userRepository: userRepository)
    }()

    public lazy var userProfileUseCase: UserProfileUseCase = {
        UserProfileUseCase(userGateway: userGateway, userRepository: userRepository)
    }()
}
