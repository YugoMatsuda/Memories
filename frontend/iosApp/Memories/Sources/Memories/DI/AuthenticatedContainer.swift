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

    // MARK: - KMP Gateways

    private lazy var kmpUserGateway: Shared.UserGateway = {
        Shared.UserGatewayImpl(apiClient: kmpApiClient)
    }()

    private lazy var kmpAlbumGateway: Shared.AlbumGateway = {
        Shared.AlbumGatewayImpl(apiClient: kmpApiClient)
    }()

    private lazy var kmpMemoryGateway: Shared.MemoryGateway = {
        Shared.MemoryGatewayImpl(apiClient: kmpApiClient)
    }()

    // MARK: - Swift Repositories (SwiftData)

    private lazy var swiftUserRepository: Repositories.UserRepository = {
        Repositories.UserRepository(userId: userId, database: database)
    }()

    private lazy var swiftAlbumRepository: Repositories.AlbumRepository = {
        Repositories.AlbumRepository(database: database)
    }()

    private lazy var swiftMemoryRepository: Repositories.MemoryRepository = {
        Repositories.MemoryRepository(database: database)
    }()

    private lazy var swiftSyncQueueRepository: Repositories.SyncQueueRepository = {
        Repositories.SyncQueueRepository(database: database)
    }()

    private lazy var swiftImageStorageRepository: Repositories.ImageStorageRepository = {
        Repositories.ImageStorageRepository(userId: userId)
    }()

    public var reachabilityRepository: ReachabilityRepositoryProtocol {
        AppConfig.reachabilityRepository
    }

    // MARK: - KMP Repository Bridges (Swift -> KMP)

    private lazy var userRepositoryBridge: UserRepositoryBridgeImpl = {
        UserRepositoryBridgeImpl(repository: swiftUserRepository)
    }()

    private lazy var albumRepositoryBridge: AlbumRepositoryBridgeImpl = {
        AlbumRepositoryBridgeImpl(repository: swiftAlbumRepository)
    }()

    private lazy var memoryRepositoryBridge: MemoryRepositoryBridgeImpl = {
        MemoryRepositoryBridgeImpl(repository: swiftMemoryRepository)
    }()

    private lazy var syncQueueRepositoryBridge: SyncQueueRepositoryBridgeImpl = {
        SyncQueueRepositoryBridgeImpl(repository: swiftSyncQueueRepository)
    }()

    private lazy var imageStorageRepositoryBridge: ImageStorageRepositoryBridgeImpl = {
        ImageStorageRepositoryBridgeImpl(repository: swiftImageStorageRepository)
    }()

    private lazy var reachabilityRepositoryBridge: ReachabilityRepositoryBridgeImpl = {
        ReachabilityRepositoryBridgeImpl(repository: reachabilityRepository)
    }()

    private lazy var authSessionRepositoryBridge: AuthSessionRepositoryBridgeImpl = {
        AuthSessionRepositoryBridgeImpl(repository: AppConfig.authSessionRepository)
    }()

    // MARK: - KMP Repositories (via Bridge)

    private lazy var kmpUserRepository: Shared.UserRepository = {
        Shared.UserRepositoryImpl(bridge: userRepositoryBridge)
    }()

    private lazy var kmpAlbumRepository: Shared.AlbumRepository = {
        Shared.AlbumRepositoryImpl(bridge: albumRepositoryBridge)
    }()

    private lazy var kmpMemoryRepository: Shared.MemoryRepository = {
        Shared.MemoryRepositoryImpl(bridge: memoryRepositoryBridge)
    }()

    private lazy var kmpSyncQueueRepository: Shared.SyncQueueRepository = {
        Shared.SyncQueueRepositoryImpl(bridge: syncQueueRepositoryBridge)
    }()

    private lazy var kmpImageStorageRepository: Shared.ImageStorageRepository = {
        Shared.ImageStorageRepositoryImpl(bridge: imageStorageRepositoryBridge)
    }()

    private lazy var kmpReachabilityRepository: Shared.ReachabilityRepository = {
        Shared.ReachabilityRepositoryImpl(bridge: reachabilityRepositoryBridge)
    }()

    private lazy var kmpAuthSessionRepository: Shared.AuthSessionRepository = {
        Shared.AuthSessionRepositoryImpl(bridge: authSessionRepositoryBridge)
    }()

    // MARK: - KMP SyncQueueService

    private lazy var kmpSyncQueueService: Shared.SyncQueueService = {
        Shared.SyncQueueServiceImpl(
            syncQueueRepository: kmpSyncQueueRepository,
            albumRepository: kmpAlbumRepository,
            memoryRepository: kmpMemoryRepository,
            userRepository: kmpUserRepository,
            albumGateway: kmpAlbumGateway,
            memoryGateway: kmpMemoryGateway,
            userGateway: kmpUserGateway,
            imageStorageRepository: kmpImageStorageRepository,
            reachabilityRepository: kmpReachabilityRepository
        )
    }()

    // MARK: - KMP UseCases

    public lazy var splashUseCase: SplashUseCaseProtocol = {
        let kmpUseCase = Shared.SplashUseCaseImpl(
            userGateway: kmpUserGateway,
            userRepository: kmpUserRepository,
            authSessionRepository: kmpAuthSessionRepository,
            reachabilityRepository: kmpReachabilityRepository,
            syncQueueRepository: kmpSyncQueueRepository
        )
        return SplashUseCaseAdapter(kmpUseCase: kmpUseCase)
    }()

    public lazy var albumListUseCase: AlbumListUseCaseProtocol = {
        let kmpUseCase = Shared.AlbumListUseCaseImpl(
            userRepository: kmpUserRepository,
            albumRepository: kmpAlbumRepository,
            albumGateway: kmpAlbumGateway,
            reachabilityRepository: kmpReachabilityRepository,
            syncQueueService: kmpSyncQueueService,
            syncQueueRepository: kmpSyncQueueRepository
        )
        return AlbumListUseCaseAdapter(
            kmpUseCase: kmpUseCase,
            reachabilityRepository: reachabilityRepository
        )
    }()

    public lazy var userProfileUseCase: UserProfileUseCaseProtocol = {
        let kmpUseCase = Shared.UserProfileUseCaseImpl(
            userGateway: kmpUserGateway,
            userRepository: kmpUserRepository,
            authSessionRepository: kmpAuthSessionRepository,
            syncQueueService: kmpSyncQueueService,
            reachabilityRepository: kmpReachabilityRepository,
            imageStorageRepository: kmpImageStorageRepository
        )
        return UserProfileUseCaseAdapter(kmpUseCase: kmpUseCase)
    }()

    public lazy var albumFormUseCase: AlbumFormUseCaseProtocol = {
        let kmpUseCase = Shared.AlbumFormUseCaseImpl(
            albumRepository: kmpAlbumRepository,
            albumGateway: kmpAlbumGateway,
            syncQueueService: kmpSyncQueueService,
            reachabilityRepository: kmpReachabilityRepository,
            imageStorageRepository: kmpImageStorageRepository
        )
        return AlbumFormUseCaseAdapter(kmpUseCase: kmpUseCase)
    }()

    public lazy var memoryFormUseCase: MemoryFormUseCaseProtocol = {
        let kmpUseCase = Shared.MemoryFormUseCaseImpl(
            memoryRepository: kmpMemoryRepository,
            memoryGateway: kmpMemoryGateway,
            syncQueueService: kmpSyncQueueService,
            reachabilityRepository: kmpReachabilityRepository,
            imageStorageRepository: kmpImageStorageRepository
        )
        return MemoryFormUseCaseAdapter(kmpUseCase: kmpUseCase)
    }()

    public lazy var albumDetailUseCase: AlbumDetailUseCaseProtocol = {
        let kmpUseCase = Shared.AlbumDetailUseCaseImpl(
            memoryRepository: kmpMemoryRepository,
            albumRepository: kmpAlbumRepository,
            albumGateway: kmpAlbumGateway,
            memoryGateway: kmpMemoryGateway,
            reachabilityRepository: kmpReachabilityRepository
        )
        return AlbumDetailUseCaseAdapter(kmpUseCase: kmpUseCase)
    }()

    public lazy var syncQueuesUseCase: SyncQueuesUseCaseProtocol = {
        let kmpUseCase = Shared.SyncQueuesUseCaseImpl(
            syncQueueRepository: kmpSyncQueueRepository,
            albumRepository: kmpAlbumRepository,
            memoryRepository: kmpMemoryRepository,
            userRepository: kmpUserRepository
        )
        return SyncQueuesUseCaseAdapter(kmpUseCase: kmpUseCase)
    }()

}
