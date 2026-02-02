package com.example.memoriesapp.gateway

import com.example.memoriesapp.api.client.ApiClient
import com.example.memoriesapp.api.request.LoginRequest
import com.example.memoriesapp.api.response.TokenResponse
import kotlinx.serialization.json.Json

/**
 * Authentication gateway implementation
 */
class AuthGatewayImpl(
    private val apiClient: ApiClient
) : AuthGateway {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    override suspend fun login(username: String, password: String): TokenResponse {
        val request = LoginRequest(username = username, password = password)
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(TokenResponse.serializer(), data.decodeToString())
    }
}
