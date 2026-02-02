package com.example.memoriesapp.gateway

import com.example.memoriesapp.api.client.ApiClient
import com.example.memoriesapp.api.request.AvatarUploadRequest
import com.example.memoriesapp.api.request.GetUserRequest
import com.example.memoriesapp.api.request.UserUpdateRequest
import com.example.memoriesapp.api.response.UserResponse
import kotlinx.serialization.json.Json

/**
 * User gateway implementation
 */
class UserGatewayImpl(
    private val apiClient: ApiClient
) : UserGateway {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    override suspend fun getUser(): UserResponse {
        val request = GetUserRequest
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(UserResponse.serializer(), data.decodeToString())
    }

    override suspend fun updateUser(name: String?, birthday: String?, avatarUrl: String?): UserResponse {
        val request = UserUpdateRequest(name = name, birthday = birthday, avatarUrl = avatarUrl)
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(UserResponse.serializer(), data.decodeToString())
    }

    override suspend fun uploadAvatar(fileData: ByteArray, fileName: String, mimeType: String): UserResponse {
        val request = AvatarUploadRequest(
            fileData = fileData,
            fileName = fileName,
            mimeType = mimeType
        )
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(UserResponse.serializer(), data.decodeToString())
    }
}
