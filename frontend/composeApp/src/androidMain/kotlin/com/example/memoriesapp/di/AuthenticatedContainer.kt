package com.example.memoriesapp.di

import com.example.memoriesapp.api.client.AuthenticatedApiClient
import com.example.memoriesapp.data.repository.AlbumRepositoryImpl
import com.example.memoriesapp.data.repository.ImageStorageRepositoryImpl
import com.example.memoriesapp.data.repository.MemoryRepositoryImpl
import com.example.memoriesapp.data.repository.SyncQueueRepositoryImpl
import com.example.memoriesapp.data.repository.UserRepositoryImpl
import com.example.memoriesapp.gateway.impl.AlbumGatewayImpl
import com.example.memoriesapp.gateway.impl.MemoryGatewayImpl
import com.example.memoriesapp.gateway.impl.UserGatewayImpl
import com.example.memoriesapp.repository.AuthSessionRepository
import com.example.memoriesapp.repository.ReachabilityRepository
import com.example.memoriesapp.usecase.AlbumDetailUseCase
import com.example.memoriesapp.usecase.AlbumFormUseCase
import com.example.memoriesapp.usecase.AlbumListUseCaseWrapper
import com.example.memoriesapp.usecase.MemoryFormUseCase
import com.example.memoriesapp.usecase.SplashUseCase
import com.example.memoriesapp.usecase.SyncQueuesUseCase
import com.example.memoriesapp.usecase.UserProfileUseCase
import com.example.memoriesapp.usecase.impl.AlbumDetailUseCaseImpl
import com.example.memoriesapp.usecase.impl.AlbumFormUseCaseImpl
import com.example.memoriesapp.usecase.impl.AlbumListUseCaseImpl
import com.example.memoriesapp.usecase.impl.MemoryFormUseCaseImpl
import com.example.memoriesapp.usecase.impl.SplashUseCaseImpl
import com.example.memoriesapp.usecase.impl.SyncQueueServiceImpl
import com.example.memoriesapp.usecase.impl.SyncQueuesUseCaseImpl
import com.example.memoriesapp.usecase.impl.UserProfileUseCaseImpl

/**
 * DI container for authenticated user session.
 * Contains all use cases that require authentication.
 */
class AuthenticatedContainer(
    private val context: android.content.Context,
    private val token: String,
    private val userId: Int,
    private val baseUrl: String,
    private val authSessionRepository: AuthSessionRepository,
    private val reachabilityRepository: ReachabilityRepository
) {
    // Repositories (in-memory, no persistence)
    private val userRepository = UserRepositoryImpl(userId)
    private val albumRepository = AlbumRepositoryImpl()
    private val memoryRepository = MemoryRepositoryImpl()
    private val syncQueueRepository = SyncQueueRepositoryImpl()
    private val imageStorageRepository = ImageStorageRepositoryImpl(context)

    // API Client (authenticated)
    private val apiClient = AuthenticatedApiClient(baseUrl, token)

    // Gateways
    private val userGateway = UserGatewayImpl(apiClient)
    private val albumGateway = AlbumGatewayImpl(apiClient)
    private val memoryGateway = MemoryGatewayImpl(apiClient)

    // SyncQueueService
    private val syncQueueService = SyncQueueServiceImpl(
        syncQueueRepository = syncQueueRepository,
        albumRepository = albumRepository,
        memoryRepository = memoryRepository,
        userRepository = userRepository,
        albumGateway = albumGateway,
        memoryGateway = memoryGateway,
        userGateway = userGateway,
        imageStorageRepository = imageStorageRepository,
        reachabilityRepository = reachabilityRepository
    )

    // UseCases
    val splashUseCase: SplashUseCase by lazy {
        SplashUseCaseImpl(
            userGateway = userGateway,
            userRepository = userRepository,
            authSessionRepository = authSessionRepository,
            reachabilityRepository = reachabilityRepository,
            syncQueueRepository = syncQueueRepository
        )
    }

    val albumListUseCase: AlbumListUseCaseWrapper by lazy {
        val impl = AlbumListUseCaseImpl(
            userRepository = userRepository,
            albumRepository = albumRepository,
            albumGateway = albumGateway,
            reachabilityRepository = reachabilityRepository,
            syncQueueService = syncQueueService,
            syncQueueRepository = syncQueueRepository
        )
        AlbumListUseCaseWrapper(impl, reachabilityRepository)
    }

    val albumDetailUseCase: AlbumDetailUseCase by lazy {
        AlbumDetailUseCaseImpl(
            memoryRepository = memoryRepository,
            albumRepository = albumRepository,
            albumGateway = albumGateway,
            memoryGateway = memoryGateway,
            reachabilityRepository = reachabilityRepository
        )
    }

    val albumFormUseCase: AlbumFormUseCase by lazy {
        AlbumFormUseCaseImpl(
            albumRepository = albumRepository,
            albumGateway = albumGateway,
            syncQueueService = syncQueueService,
            reachabilityRepository = reachabilityRepository,
            imageStorageRepository = imageStorageRepository
        )
    }

    val memoryFormUseCase: MemoryFormUseCase by lazy {
        MemoryFormUseCaseImpl(
            memoryRepository = memoryRepository,
            memoryGateway = memoryGateway,
            syncQueueService = syncQueueService,
            reachabilityRepository = reachabilityRepository,
            imageStorageRepository = imageStorageRepository
        )
    }

    val userProfileUseCase: UserProfileUseCase by lazy {
        UserProfileUseCaseImpl(
            userGateway = userGateway,
            userRepository = userRepository,
            authSessionRepository = authSessionRepository,
            syncQueueService = syncQueueService,
            reachabilityRepository = reachabilityRepository,
            imageStorageRepository = imageStorageRepository
        )
    }

    val syncQueuesUseCase: SyncQueuesUseCase by lazy {
        SyncQueuesUseCaseImpl(
            syncQueueRepository = syncQueueRepository,
            albumRepository = albumRepository,
            memoryRepository = memoryRepository,
            userRepository = userRepository
        )
    }
}
