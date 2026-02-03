package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.domain.Memory

/**
 * Result of memory create operation
 */
sealed class MemoryCreateResult {
    data class Success(val memory: Memory) : MemoryCreateResult()
    data class SuccessPendingSync(val memory: Memory) : MemoryCreateResult()
    data class Failure(val error: MemoryCreateError) : MemoryCreateResult()
}

enum class MemoryCreateError {
    NETWORK_ERROR,
    IMAGE_STORAGE_FAILED,
    DATABASE_ERROR,
    UNKNOWN
}

interface MemoryFormUseCase {
    suspend fun createMemory(album: Album, title: String, imageData: ByteArray): MemoryCreateResult
}
