package com.example.memoriesapp.gateway

import com.example.memoriesapp.api.response.TokenResponse

/**
 * Authentication gateway interface
 */
interface AuthGateway {
    suspend fun login(username: String, password: String): TokenResponse
}
