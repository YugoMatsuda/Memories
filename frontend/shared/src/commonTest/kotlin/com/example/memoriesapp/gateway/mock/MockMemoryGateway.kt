package com.example.memoriesapp.gateway.mock

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.MemoryResponse
import com.example.memoriesapp.api.response.PaginatedMemoriesResponse
import com.example.memoriesapp.gateway.MemoryGateway

class MockMemoryGateway : MemoryGateway {
    private var paginatedResponse: PaginatedMemoriesResponse? = null
    private var memoryResponse: MemoryResponse? = null
    private var errorToThrow: Exception? = null

    fun setPaginatedResponse(response: PaginatedMemoriesResponse) {
        paginatedResponse = response
        errorToThrow = null
    }

    fun setMemoryResponse(response: MemoryResponse) {
        memoryResponse = response
        errorToThrow = null
    }

    fun setError(error: Exception) {
        errorToThrow = error
        paginatedResponse = null
        memoryResponse = null
    }

    override suspend fun getMemories(albumId: Int, page: Int, pageSize: Int): PaginatedMemoriesResponse {
        errorToThrow?.let { throw it }
        return paginatedResponse ?: PaginatedMemoriesResponse(
            items = emptyList(),
            page = page,
            pageSize = pageSize,
            total = 0
        )
    }

    override suspend fun uploadMemory(
        albumId: Int,
        title: String,
        imageRemoteUrl: String?,
        fileData: ByteArray?,
        fileName: String?,
        mimeType: String?
    ): MemoryResponse {
        errorToThrow?.let { throw it }
        return memoryResponse ?: throw ApiError.Unexpected(null)
    }
}
