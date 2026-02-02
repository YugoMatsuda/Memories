package com.example.memoriesapp.gateway

import com.example.memoriesapp.api.response.MemoryResponse
import com.example.memoriesapp.api.response.PaginatedMemoriesResponse

/**
 * Memory gateway interface
 */
interface MemoryGateway {
    suspend fun getMemories(albumId: Int, page: Int, pageSize: Int): PaginatedMemoriesResponse
    suspend fun uploadMemory(
        albumId: Int,
        title: String,
        imageRemoteUrl: String?,
        fileData: ByteArray?,
        fileName: String?,
        mimeType: String?
    ): MemoryResponse
}
