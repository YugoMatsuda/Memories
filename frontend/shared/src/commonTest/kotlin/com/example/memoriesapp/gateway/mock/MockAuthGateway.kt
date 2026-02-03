package com.example.memoriesapp.gateway.mock

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.TokenResponse
import com.example.memoriesapp.gateway.AuthGateway

class MockAuthGateway : AuthGateway {
    private var tokenResponse: TokenResponse? = null
    private var errorToThrow: Exception? = null
    private var capturedUsername: String? = null
    private var capturedPassword: String? = null

    fun setResponse(response: TokenResponse) {
        tokenResponse = response
        errorToThrow = null
    }

    fun setError(error: Exception) {
        errorToThrow = error
        tokenResponse = null
    }

    fun getCapturedCredentials(): Pair<String?, String?> = capturedUsername to capturedPassword

    override suspend fun login(username: String, password: String): TokenResponse {
        capturedUsername = username
        capturedPassword = password

        errorToThrow?.let { throw it }
        return tokenResponse ?: throw ApiError.Unexpected(null)
    }
}
