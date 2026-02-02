package com.example.memoriesapp.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.ImageEntityType

/**
 * Bridge interface for Swift to implement
 */
interface ImageStorageRepositoryBridge {
    fun save(data: ByteArray, entity: ImageEntityType, localId: LocalId): String
    fun get(entity: ImageEntityType, localId: LocalId): ByteArray
    fun delete(entity: ImageEntityType, localId: LocalId)
    fun getPath(entity: ImageEntityType, localId: LocalId): String
}

/**
 * iOS implementation of ImageStorageRepository
 */
class ImageStorageRepositoryImpl(
    private val bridge: ImageStorageRepositoryBridge
) : ImageStorageRepository {

    override fun save(data: ByteArray, entity: ImageEntityType, localId: LocalId): String =
        bridge.save(data, entity, localId)

    override fun get(entity: ImageEntityType, localId: LocalId): ByteArray =
        bridge.get(entity, localId)

    override fun delete(entity: ImageEntityType, localId: LocalId) =
        bridge.delete(entity, localId)

    override fun getPath(entity: ImageEntityType, localId: LocalId): String =
        bridge.getPath(entity, localId)
}
