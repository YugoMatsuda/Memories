import Foundation
import APIClients
import APIGateways
import Repositories
import UseCases

public enum AppConfig {
    public static let baseURL = URL(string: "http://localhost:8000")!

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
