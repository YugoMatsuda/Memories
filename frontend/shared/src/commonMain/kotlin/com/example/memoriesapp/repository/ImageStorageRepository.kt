package com.example.memoriesapp.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.ImageEntityType

/**
 * Repository interface for local image storage
 */
interface ImageStorageRepository {
    fun save(data: ByteArray, entity: ImageEntityType, localId: LocalId): String
    fun get(entity: ImageEntityType, localId: LocalId): ByteArray
    fun delete(entity: ImageEntityType, localId: LocalId)
    fun getPath(entity: ImageEntityType, localId: LocalId): String
}
