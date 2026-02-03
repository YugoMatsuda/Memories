package com.example.memoriesapp.di

import com.example.memoriesapp.api.client.PublicApiClient
import com.example.memoriesapp.data.repository.AuthSessionRepositoryImpl
import com.example.memoriesapp.data.repository.DebugReachabilityRepository
import com.example.memoriesapp.data.repository.ReachabilityRepositoryImpl
import com.example.memoriesapp.gateway.AuthGatewayImpl
import com.example.memoriesapp.repository.AuthSessionRepository
import com.example.memoriesapp.repository.ReachabilityRepository
import com.example.memoriesapp.usecase.LoginUseCase
import com.example.memoriesapp.usecase.LoginUseCaseImpl
import com.example.memoriesapp.usecase.RootUseCase
import com.example.memoriesapp.usecase.RootUseCaseImpl

/**
 * Online state configuration for debugging network conditions.
 */
sealed class OnlineState {
    data class Debug(val initialState: Boolean) : OnlineState()
    data object Production : OnlineState()
}

/**
 * Application-level DI container.
 * Contains shared instances and unauthenticated use cases.
 */
class AppContainer(
    private val context: android.content.Context,
    val baseUrl: String = "http://10.0.2.2:8000" // Android emulator localhost
) {
    companion object {
        // .Debug(initialState = true)  - Debug mode, starts online
        // .Debug(initialState = false) - Debug mode, starts offline
        // .Production                  - Production mode, uses actual network state
        val onlineState: OnlineState = OnlineState.Production
    }

    // Shared Repositories (with secure persistence)
    val authSessionRepository: AuthSessionRepository = AuthSessionRepositoryImpl(context)

    val reachabilityRepository: ReachabilityRepository = when (val state = onlineState) {
        is OnlineState.Debug -> DebugReachabilityRepository(state.initialState)
        is OnlineState.Production -> ReachabilityRepositoryImpl()
    }

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
            context = context,
            token = token,
            userId = userId,
            baseUrl = baseUrl,
            authSessionRepository = authSessionRepository,
            reachabilityRepository = reachabilityRepository
        )
    }
}
