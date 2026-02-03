package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.User

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

interface SplashUseCase {
    suspend fun launchApp(): LaunchAppResult
    fun clearSession()
}
