package com.example.memoriesapp.gateway

import com.example.memoriesapp.api.response.UserResponse

/**
 * User gateway interface
 */
interface UserGateway {
    suspend fun getUser(): UserResponse
    suspend fun updateUser(name: String?, birthday: String?, avatarUrl: String?): UserResponse
    suspend fun uploadAvatar(fileData: ByteArray, fileName: String, mimeType: String): UserResponse
}
