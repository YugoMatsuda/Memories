package com.example.memoriesapp.gateway.impl

import com.example.memoriesapp.api.client.ApiClient
import com.example.memoriesapp.api.request.GetMemoriesRequest
import com.example.memoriesapp.api.request.MemoryUploadRequest
import com.example.memoriesapp.api.response.MemoryResponse
import com.example.memoriesapp.api.response.PaginatedMemoriesResponse
import com.example.memoriesapp.gateway.MemoryGateway
import kotlinx.serialization.json.Json

/**
 * Memory gateway implementation
 */
class MemoryGatewayImpl(
    private val apiClient: ApiClient
) : MemoryGateway {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    override suspend fun getMemories(albumId: Int, page: Int, pageSize: Int): PaginatedMemoriesResponse {
        val request = GetMemoriesRequest(albumId = albumId, page = page, pageSize = pageSize)
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(PaginatedMemoriesResponse.serializer(), data.decodeToString())
    }

    override suspend fun uploadMemory(
        albumId: Int,
        title: String,
        imageRemoteUrl: String?,
        fileData: ByteArray?,
        fileName: String?,
        mimeType: String?
    ): MemoryResponse {
        val request = MemoryUploadRequest(
            albumId = albumId,
            title = title,
            imageRemoteUrl = imageRemoteUrl,
            fileData = fileData,
            fileName = fileName,
            mimeType = mimeType
        )
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(MemoryResponse.serializer(), data.decodeToString())
    }
}
