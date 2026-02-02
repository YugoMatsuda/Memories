package com.example.memoriesapp.data.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.ImageEntityType
import com.example.memoriesapp.repository.ImageStorageRepository

/**
 * In-memory implementation of ImageStorageRepository.
 * No persistence - images are lost on app restart.
 */
class ImageStorageRepositoryImpl : ImageStorageRepository {
    private val storage = mutableMapOf<String, ByteArray>()

    override fun save(data: ByteArray, entity: ImageEntityType, localId: LocalId): String {
        val path = getPath(entity, localId)
        storage[path] = data
        return path
    }

    override fun get(entity: ImageEntityType, localId: LocalId): ByteArray {
        val path = getPath(entity, localId)
        return storage[path] ?: ByteArray(0)
    }

    override fun delete(entity: ImageEntityType, localId: LocalId) {
        val path = getPath(entity, localId)
        storage.remove(path)
    }

    override fun getPath(entity: ImageEntityType, localId: LocalId): String {
        return "memory://${entity.path}/$localId"
    }
}
