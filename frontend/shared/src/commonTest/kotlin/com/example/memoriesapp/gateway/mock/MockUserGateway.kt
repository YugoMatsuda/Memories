package com.example.memoriesapp.gateway.mock

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.UserResponse
import com.example.memoriesapp.gateway.UserGateway

class MockUserGateway : UserGateway {
    private var userResponse: UserResponse? = null
    private var errorToThrow: Exception? = null

    fun setResponse(response: UserResponse) {
        userResponse = response
        errorToThrow = null
    }

    fun setError(error: Exception) {
        errorToThrow = error
        userResponse = null
    }

    override suspend fun getUser(): UserResponse {
        errorToThrow?.let { throw it }
        return userResponse ?: throw ApiError.NotFound
    }

    override suspend fun updateUser(name: String?, birthday: String?, avatarUrl: String?): UserResponse {
        errorToThrow?.let { throw it }
        return userResponse ?: throw ApiError.NotFound
    }

    override suspend fun uploadAvatar(fileData: ByteArray, fileName: String, mimeType: String): UserResponse {
        errorToThrow?.let { throw it }
        return userResponse ?: throw ApiError.NotFound
    }
}
