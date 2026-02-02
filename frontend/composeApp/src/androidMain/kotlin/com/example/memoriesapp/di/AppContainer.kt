package com.example.memoriesapp.di

import com.example.memoriesapp.api.client.PublicApiClient
import com.example.memoriesapp.data.repository.AuthSessionRepositoryImpl
import com.example.memoriesapp.data.repository.ReachabilityRepositoryImpl
import com.example.memoriesapp.gateway.AuthGatewayImpl
import com.example.memoriesapp.repository.AuthSessionRepository
import com.example.memoriesapp.repository.ReachabilityRepository
import com.example.memoriesapp.usecase.LoginUseCase
import com.example.memoriesapp.usecase.LoginUseCaseImpl
import com.example.memoriesapp.usecase.RootUseCase
import com.example.memoriesapp.usecase.RootUseCaseImpl

/**
 * Application-level DI container.
 * Contains shared instances and unauthenticated use cases.
 *
 * Mirrors iOS AppConfig structure.
 */
class AppContainer(
    private val baseUrl: String = "http://10.0.2.2:8000" // Android emulator localhost
) {
    // Shared Repositories (in-memory, no persistence)
    val authSessionRepository: AuthSessionRepository = AuthSessionRepositoryImpl()
    val reachabilityRepository: ReachabilityRepository = ReachabilityRepositoryImpl()

    // API Client (unauthenticated)
    private val publicApiClient = PublicApiClient(baseUrl)

    // Gateway
    private val authGateway = AuthGatewayImpl(publicApiClient)

    // Unauthenticated UseCases
    val loginUseCase: LoginUseCase by lazy {
        LoginUseCaseImpl(
            authGateway = authGateway,
            authSessionRepository = authSessionRepository
        )
    }

    val rootUseCase: RootUseCase by lazy {
        RootUseCaseImpl(authSessionRepository = authSessionRepository)
    }

    // Factory for authenticated container
    fun createAuthenticatedContainer(token: String, userId: Int): AuthenticatedContainer {
        return AuthenticatedContainer(
            token = token,
            userId = userId,
            baseUrl = baseUrl,
            authSessionRepository = authSessionRepository,
            reachabilityRepository = reachabilityRepository
        )
    }
}
