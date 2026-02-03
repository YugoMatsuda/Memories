package com.example.memoriesapp.mapper

import com.example.memoriesapp.api.response.AlbumResponse
import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class AlbumMapperTest {

    @Test
    fun toDomain_mapsBasicFields() {
        val response = AlbumResponse(
            id = 5,
            title = "Summer Vacation",
            coverImageUrl = "/uploads/cover.jpg",
            createdAt = "2024-06-15T10:30:00Z"
        )

        val album = AlbumMapper.toDomain(response)

        assertEquals(5, album.serverId)
        assertEquals("Summer Vacation", album.title)
        assertEquals("/uploads/cover.jpg", album.coverImageUrl)
        assertNull(album.coverImageLocalPath)
        assertEquals(SyncStatus.SYNCED, album.syncStatus)
    }

    @Test
    fun toDomain_generatesNewLocalId() {
        val response = AlbumResponse(
            id = 1,
            title = "Test",
            createdAt = "2024-01-01T00:00:00Z"
        )

        val album1 = AlbumMapper.toDomain(response)
        val album2 = AlbumMapper.toDomain(response)

        assertNotNull(album1.localId)
        assertNotNull(album2.localId)
        // Each call generates a new localId
        assertEquals(false, album1.localId == album2.localId)
    }

    @Test
    fun toDomain_withLocalId_preservesExistingLocalId() {
        val existingLocalId = LocalId.generate()
        val response = AlbumResponse(
            id = 3,
            title = "Preserved LocalId Album",
            createdAt = "2024-03-01T12:00:00Z"
        )

        val album = AlbumMapper.toDomain(response, existingLocalId)

        assertEquals(existingLocalId, album.localId)
        assertEquals(3, album.serverId)
        assertEquals("Preserved LocalId Album", album.title)
    }

    @Test
    fun toDomain_withNullCoverImageUrl() {
        val response = AlbumResponse(
            id = 2,
            title = "No Cover Album",
            coverImageUrl = null,
            createdAt = "2024-02-01T00:00:00Z"
        )

        val album = AlbumMapper.toDomain(response)

        assertNull(album.coverImageUrl)
        assertNull(album.displayCoverImage)
    }

    @Test
    fun toDomain_parsesValidTimestamp() {
        val response = AlbumResponse(
            id = 1,
            title = "Test",
            createdAt = "2024-06-15T10:30:00Z"
        )

        val album = AlbumMapper.toDomain(response)

        // Verify the timestamp was parsed correctly
        assertEquals("2024-06-15T10:30:00Z", album.createdAt.toString())
    }

    @Test
    fun toDomain_handlesInvalidTimestamp() {
        val response = AlbumResponse(
            id = 1,
            title = "Test",
            createdAt = "invalid-date"
        )

        // Should not throw, falls back to Timestamp.now()
        val album = AlbumMapper.toDomain(response)

        assertNotNull(album.createdAt)
    }

    @Test
    fun toDomain_setsStatusToSynced() {
        val response = AlbumResponse(
            id = 1,
            title = "Test",
            createdAt = "2024-01-01T00:00:00Z"
        )

        val album = AlbumMapper.toDomain(response)

        assertEquals(SyncStatus.SYNCED, album.syncStatus)
        assertEquals(true, album.isSynced)
    }
}
