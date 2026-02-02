package com.example.memoriesapp.usecase

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.gateway.UserGateway
import com.example.memoriesapp.mapper.UserMapper
import com.example.memoriesapp.repository.AuthSessionRepository
import com.example.memoriesapp.repository.ReachabilityRepository
import com.example.memoriesapp.repository.SyncQueueRepository
import com.example.memoriesapp.repository.UserRepository

/**
 * Result of launching the app
 */
sealed class LaunchAppResult {
    data class Success(val user: User) : LaunchAppResult()
    data class Failure(val error: LaunchAppError) : LaunchAppResult()
}

enum class LaunchAppError {
    SESSION_EXPIRED,
    NETWORK_ERROR,
    SERVER_ERROR,
    OFFLINE_NO_CACHE,
    UNKNOWN
}

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
