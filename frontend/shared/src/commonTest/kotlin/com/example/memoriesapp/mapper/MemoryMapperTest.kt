package com.example.memoriesapp.mapper

import com.example.memoriesapp.api.response.MemoryResponse
import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class MemoryMapperTest {

    private val albumLocalId = LocalId.generate()

    @Test
    fun toDomain_mapsBasicFields() {
        val response = MemoryResponse(
            id = 10,
            albumId = 5,
            title = "Beach Sunset",
            imageLocalUri = "/uploads/sunset.jpg",
            imageRemoteUrl = null,
            createdAt = "2024-06-15T18:30:00Z"
        )

        val memory = MemoryMapper.toDomain(response, albumLocalId)

        assertNotNull(memory)
        assertEquals(10, memory.serverId)
        assertEquals(5, memory.albumId)
        assertEquals(albumLocalId, memory.albumLocalId)
        assertEquals("Beach Sunset", memory.title)
        assertEquals("/uploads/sunset.jpg", memory.imageUrl)
        assertNull(memory.imageLocalPath)
        assertEquals(SyncStatus.SYNCED, memory.syncStatus)
    }

    @Test
    fun toDomain_generatesNewLocalId() {
        val response = MemoryResponse(
            id = 1,
            albumId = 1,
            title = "Test",
            imageLocalUri = "/test.jpg",
            createdAt = "2024-01-01T00:00:00Z"
        )

        val memory1 = MemoryMapper.toDomain(response, albumLocalId)
        val memory2 = MemoryMapper.toDomain(response, albumLocalId)

        assertNotNull(memory1)
        assertNotNull(memory2)
        // Each call generates a new localId
        assertEquals(false, memory1.localId == memory2.localId)
    }

    @Test
    fun toDomain_withLocalId_preservesExistingLocalId() {
        val existingLocalId = LocalId.generate()
        val response = MemoryResponse(
            id = 3,
            albumId = 2,
            title = "Preserved Memory",
            imageLocalUri = "/preserved.jpg",
            createdAt = "2024-03-01T12:00:00Z"
        )

        val memory = MemoryMapper.toDomain(response, existingLocalId, albumLocalId)

        assertNotNull(memory)
        assertEquals(existingLocalId, memory.localId)
        assertEquals(albumLocalId, memory.albumLocalId)
    }

    @Test
    fun toDomain_prefersImageLocalUriOverRemoteUrl() {
        val response = MemoryResponse(
            id = 1,
            albumId = 1,
            title = "Test",
            imageLocalUri = "/local/image.jpg",
            imageRemoteUrl = "https://example.com/remote.jpg",
            createdAt = "2024-01-01T00:00:00Z"
        )

        val memory = MemoryMapper.toDomain(response, albumLocalId)

        assertNotNull(memory)
        assertEquals("/local/image.jpg", memory.imageUrl)
    }

    @Test
    fun toDomain_usesRemoteUrlWhenLocalUriIsNull() {
        val response = MemoryResponse(
            id = 1,
            albumId = 1,
            title = "Test",
            imageLocalUri = null,
            imageRemoteUrl = "https://example.com/remote.jpg",
            createdAt = "2024-01-01T00:00:00Z"
        )

        val memory = MemoryMapper.toDomain(response, albumLocalId)

        assertNotNull(memory)
        assertEquals("https://example.com/remote.jpg", memory.imageUrl)
    }

    @Test
    fun toDomain_returnsNullWhenBothImageUrlsAreNull() {
        val response = MemoryResponse(
            id = 1,
            albumId = 1,
            title = "No Image Memory",
            imageLocalUri = null,
            imageRemoteUrl = null,
            createdAt = "2024-01-01T00:00:00Z"
        )

        val memory = MemoryMapper.toDomain(response, albumLocalId)

        assertNull(memory)
    }

    @Test
    fun toDomain_withLocalId_returnsNullWhenBothImageUrlsAreNull() {
        val existingLocalId = LocalId.generate()
        val response = MemoryResponse(
            id = 1,
            albumId = 1,
            title = "No Image Memory",
            imageLocalUri = null,
            imageRemoteUrl = null,
            createdAt = "2024-01-01T00:00:00Z"
        )

        val memory = MemoryMapper.toDomain(response, existingLocalId, albumLocalId)

        assertNull(memory)
    }

    @Test
    fun toDomain_parsesValidTimestamp() {
        val response = MemoryResponse(
            id = 1,
            albumId = 1,
            title = "Test",
            imageLocalUri = "/test.jpg",
            createdAt = "2024-06-15T18:30:00Z"
        )

        val memory = MemoryMapper.toDomain(response, albumLocalId)

        assertNotNull(memory)
        assertEquals("2024-06-15T18:30:00Z", memory.createdAt.toString())
    }

    @Test
    fun toDomain_handlesInvalidTimestamp() {
        val response = MemoryResponse(
            id = 1,
            albumId = 1,
            title = "Test",
            imageLocalUri = "/test.jpg",
            createdAt = "invalid-date"
        )

        // Should not throw, falls back to Timestamp.now()
        val memory = MemoryMapper.toDomain(response, albumLocalId)

        assertNotNull(memory)
        assertNotNull(memory.createdAt)
    }

    @Test
    fun toDomain_setsStatusToSynced() {
        val response = MemoryResponse(
            id = 1,
            albumId = 1,
            title = "Test",
            imageLocalUri = "/test.jpg",
            createdAt = "2024-01-01T00:00:00Z"
        )

        val memory = MemoryMapper.toDomain(response, albumLocalId)

        assertNotNull(memory)
        assertEquals(SyncStatus.SYNCED, memory.syncStatus)
        assertEquals(true, memory.isSynced)
    }
}
