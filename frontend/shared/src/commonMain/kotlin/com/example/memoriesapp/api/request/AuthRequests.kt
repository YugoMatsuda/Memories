package com.example.memoriesapp.api.request

import com.example.memoriesapp.api.client.ApiRequest
import com.example.memoriesapp.api.client.HttpMethod
import kotlinx.serialization.Serializable

/**
 * Login request
 * POST /auth/login
 */
data class LoginRequest(
    val username: String,
    val password: String
) : ApiRequest {
    override val path: String = "/auth/login"
    override val method: HttpMethod = HttpMethod.POST
    override val body: Any = LoginBody(username, password)
}

@Serializable
internal data class LoginBody(
    val username: String,
    val password: String
)
