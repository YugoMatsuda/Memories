package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.domain.AuthSession
import com.example.memoriesapp.gateway.AuthGateway
import com.example.memoriesapp.repository.AuthSessionRepository
import com.example.memoriesapp.usecase.LoginError
import com.example.memoriesapp.usecase.LoginResult
import com.example.memoriesapp.usecase.LoginUseCase

/**
 * UseCase for user login
 */
class LoginUseCaseImpl(
    private val authGateway: AuthGateway,
    private val authSessionRepository: AuthSessionRepository
) : LoginUseCase {
    override suspend fun login(username: String, password: String): LoginResult {
        return try {
            val response = authGateway.login(username, password)
            val session = AuthSession(
                token = response.token,
                userId = response.userId
            )
            authSessionRepository.save(session)
            LoginResult.Success(session)
        } catch (e: ApiError) {
            LoginResult.Failure(mapError(e))
        } catch (e: Exception) {
            LoginResult.Failure(LoginError.UNKNOWN)
        }
    }

    private fun mapError(error: ApiError): LoginError {
        return when (error) {
            is ApiError.InvalidApiToken, is ApiError.Forbidden -> LoginError.INVALID_CREDENTIALS
            is ApiError.NetworkError, is ApiError.Timeout -> LoginError.NETWORK_ERROR
            is ApiError.ServerError, is ApiError.ServiceUnavailable -> LoginError.SERVER_ERROR
            else -> LoginError.UNKNOWN
        }
    }
}
