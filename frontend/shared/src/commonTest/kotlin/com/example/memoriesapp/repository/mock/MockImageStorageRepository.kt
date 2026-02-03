package com.example.memoriesapp.repository.mock

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.ImageEntityType
import com.example.memoriesapp.repository.ImageStorageRepository

class MockImageStorageRepository : ImageStorageRepository {
    private val storage = mutableMapOf<String, ByteArray>()
    private var shouldThrowOnSave = false
    private var shouldThrowOnGet = false

    override fun save(data: ByteArray, entity: ImageEntityType, localId: LocalId): String {
        if (shouldThrowOnSave) throw Exception("Storage error")
        val path = getPath(entity, localId)
        storage[path] = data
        return path
    }

    override fun get(entity: ImageEntityType, localId: LocalId): ByteArray {
        if (shouldThrowOnGet) throw Exception("Storage error")
        val path = getPath(entity, localId)
        return storage[path] ?: throw Exception("File not found")
    }

    override fun delete(entity: ImageEntityType, localId: LocalId) {
        val path = getPath(entity, localId)
        storage.remove(path)
    }

    override fun getPath(entity: ImageEntityType, localId: LocalId): String {
        return "/mock/${entity.name}/${localId}"
    }

    // Test helpers
    fun setShouldThrowOnSave(shouldThrow: Boolean) {
        shouldThrowOnSave = shouldThrow
    }

    fun setShouldThrowOnGet(shouldThrow: Boolean) {
        shouldThrowOnGet = shouldThrow
    }

    fun getStoredData(): Map<String, ByteArray> = storage.toMap()
}
