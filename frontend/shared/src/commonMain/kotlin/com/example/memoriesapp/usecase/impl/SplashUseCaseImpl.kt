package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.gateway.UserGateway
import com.example.memoriesapp.mapper.UserMapper
import com.example.memoriesapp.repository.AuthSessionRepository
import com.example.memoriesapp.repository.ReachabilityRepository
import com.example.memoriesapp.repository.SyncQueueRepository
import com.example.memoriesapp.repository.UserRepository
import com.example.memoriesapp.usecase.LaunchAppError
import com.example.memoriesapp.usecase.LaunchAppResult
import com.example.memoriesapp.usecase.SplashUseCase

/**
 * UseCase for splash screen / app initialization
 */
class SplashUseCaseImpl(
    private val userGateway: UserGateway,
    private val userRepository: UserRepository,
    private val authSessionRepository: AuthSessionRepository,
    private val reachabilityRepository: ReachabilityRepository,
    private val syncQueueRepository: SyncQueueRepository
) : SplashUseCase {
    override suspend fun launchApp(): LaunchAppResult {
        syncQueueRepository.refreshState()

        return if (reachabilityRepository.isConnected) {
            try {
                val response = userGateway.getUser()
                val user = UserMapper.toDomain(response)
                try {
                    userRepository.set(user)
                } catch (e: Exception) {
                    // Log but continue - cache failure shouldn't block launch
                    println("[SplashUseCase] Failed to save user to cache: $e")
                }
                LaunchAppResult.Success(user)
            } catch (e: ApiError) {
                // Fallback to cache on error
                val cachedUser = userRepository.get()
                if (cachedUser != null) {
                    userRepository.notify(cachedUser)
                    LaunchAppResult.Success(cachedUser)
                } else {
                    LaunchAppResult.Failure(mapError(e))
                }
            } catch (e: Exception) {
                // Fallback to cache on error
                val cachedUser = userRepository.get()
                if (cachedUser != null) {
                    userRepository.notify(cachedUser)
                    LaunchAppResult.Success(cachedUser)
                } else {
                    LaunchAppResult.Failure(LaunchAppError.UNKNOWN)
                }
            }
        } else {
            // Offline: use cache
            val cachedUser = userRepository.get()
            if (cachedUser != null) {
                userRepository.notify(cachedUser)
                LaunchAppResult.Success(cachedUser)
            } else {
                LaunchAppResult.Failure(LaunchAppError.OFFLINE_NO_CACHE)
            }
        }
    }

    override fun clearSession() {
        authSessionRepository.clearSession()
    }

    private fun mapError(error: ApiError): LaunchAppError {
        return when (error) {
            is ApiError.InvalidApiToken -> LaunchAppError.SESSION_EXPIRED
            is ApiError.NetworkError, is ApiError.Timeout -> LaunchAppError.NETWORK_ERROR
            is ApiError.ServerError, is ApiError.ServiceUnavailable -> LaunchAppError.SERVER_ERROR
            else -> LaunchAppError.UNKNOWN
        }
    }
}
