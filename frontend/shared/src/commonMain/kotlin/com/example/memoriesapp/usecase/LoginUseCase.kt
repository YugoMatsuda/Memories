package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.AuthSession

/**
 * Result of login operation
 */
sealed class LoginResult {
    data class Success(val session: AuthSession) : LoginResult()
    data class Failure(val error: LoginError) : LoginResult()
}

enum class LoginError {
    INVALID_CREDENTIALS,
    NETWORK_ERROR,
    SERVER_ERROR,
    UNKNOWN
}

interface LoginUseCase {
    suspend fun login(username: String, password: String): LoginResult
}
