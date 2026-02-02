package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.Album

interface MemoryFormUseCase {
    suspend fun createMemory(album: Album, title: String, imageData: ByteArray): MemoryCreateResult
}
