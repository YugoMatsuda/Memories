import Foundation
import SwiftData
import APIGateways
import Domains
import Repositories
import UseCases
@preconcurrency import Shared

@MainActor
public final class AuthenticatedContainer {
    private let token: String
    private let userId: Int

    public init(token: String, userId: Int) {
        self.token = token
        self.userId = userId
    }

    // MARK: - Infrastructure

    private lazy var database: SwiftDatabase = {
        try! SwiftDatabase.create(
            for: userId,
            modelTypes: [
                LocalAlbum.self,
                LocalUser.self,
                LocalMemory.self,
                LocalSyncOperation.self
            ]
        )
    }()

    // MARK: - KMP API Client

    private lazy var kmpApiClient: Shared.AuthenticatedApiClient = {
        Shared.AuthenticatedApiClient(baseUrl: AppConfig.baseURL.absoluteString, apiToken: token)
    }()

    // MARK: - KMP Gateways (wrapped with adapters)

    private lazy var userGateway: UserGatewayProtocol = {
        let kmpGateway = Shared.UserGatewayImpl(apiClient: kmpApiClient)
        return UserGatewayAdapter(kmpGateway: kmpGateway)
    }()

    private lazy var albumGateway: AlbumGatewayProtocol = {
        let kmpGateway = Shared.AlbumGatewayImpl(apiClient: kmpApiClient)
        return AlbumGatewayAdapter(kmpGateway: kmpGateway)
    }()

    private lazy var memoryGateway: MemoryGatewayProtocol = {
        let kmpGateway = Shared.MemoryGatewayImpl(apiClient: kmpApiClient)
        return MemoryGatewayAdapter(kmpGateway: kmpGateway)
    }()

    // MARK: - Repositories

    private lazy var userRepository: UserRepository = {
        UserRepository(userId: userId, database: database)
    }()

    private lazy var albumRepository: AlbumRepository = {
        AlbumRepository(database: database)
    }()

    private lazy var memoryRepository: MemoryRepository = {
        MemoryRepository(database: database)
    }()

    public lazy var syncQueueRepository: SyncQueueRepository = {
        SyncQueueRepository(database: database)
    }()

    private lazy var imageStorageRepository: ImageStorageRepository = {
        ImageStorageRepository(userId: userId)
    }()

    public var reachabilityRepository: ReachabilityRepositoryProtocol {
        AppConfig.reachabilityRepository
    }

    // MARK: - Services

    private lazy var syncQueueService: SyncQueueService = {
        SyncQueueService(
            syncQueueRepository: syncQueueRepository,
            albumRepository: albumRepository,
            memoryRepository: memoryRepository,
            userRepository: userRepository,
            albumGateway: albumGateway,
            memoryGateway: memoryGateway,
            userGateway: userGateway,
            imageStorageRepository: imageStorageRepository,
            reachabilityRepository: reachabilityRepository
        )
    }()

    // MARK: - UseCases

    public lazy var splashUseCase: SplashUseCase = {
        SplashUseCase(
            userGateway: userGateway,
            userRepository: userRepository,
            authSessionRepository: AppConfig.authSessionRepository,
            reachabilityRepository: reachabilityRepository,
            syncQueueRepository: syncQueueRepository
        )
    }()


    public lazy var albumListUseCase: AlbumListUseCase = {
        AlbumListUseCase(
            userRepository: userRepository,
            albumRepository: albumRepository,
            albumGateway: albumGateway,
            reachabilityRepository: reachabilityRepository,
            syncQueueService: syncQueueService,
            syncQueueRepository: syncQueueRepository
        )
    }()

    public lazy var userProfileUseCase: UserProfileUseCase = {
        UserProfileUseCase(
            userGateway: userGateway,
            userRepository: userRepository,
            authSessionRepository: AppConfig.authSessionRepository,
            syncQueueService: syncQueueService,
            reachabilityRepository: reachabilityRepository,
            imageStorageRepository: imageStorageRepository
        )
    }()

    public lazy var albumFormUseCase: AlbumFormUseCase = {
        AlbumFormUseCase(
            albumRepository: albumRepository,
            albumGateway: albumGateway,
            syncQueueService: syncQueueService,
            reachabilityRepository: reachabilityRepository,
            imageStorageRepository: imageStorageRepository
        )
    }()

    public lazy var memoryFormUseCase: MemoryFormUseCase = {
        MemoryFormUseCase(
            memoryRepository: memoryRepository,
            memoryGateway: memoryGateway,
            syncQueueService: syncQueueService,
            reachabilityRepository: reachabilityRepository,
            imageStorageRepository: imageStorageRepository
        )
    }()

    public lazy var albumDetailUseCase: AlbumDetailUseCase = {
        AlbumDetailUseCase(
            memoryRepository: memoryRepository,
            albumRepository: albumRepository,
            albumGateway: albumGateway,
            memoryGateway: memoryGateway,
            reachabilityRepository: reachabilityRepository
        )
    }()

    public lazy var syncQueuesUseCase: SyncQueuesUseCase = {
        SyncQueuesUseCase(
            syncQueueRepository: syncQueueRepository,
            albumRepository: albumRepository,
            memoryRepository: memoryRepository,
            userRepository: userRepository
        )
    }()
}
