package com.example.memoriesapp.domain

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class AlbumTest {

    private fun createAlbum(
        serverId: Int? = 1,
        coverImageUrl: String? = null,
        coverImageLocalPath: String? = null,
        syncStatus: SyncStatus = SyncStatus.SYNCED
    ) = Album(
        serverId = serverId,
        localId = LocalId.generate(),
        title = "Test Album",
        coverImageUrl = coverImageUrl,
        coverImageLocalPath = coverImageLocalPath,
        createdAt = Timestamp.now(),
        syncStatus = syncStatus
    )

    // isSynced tests

    @Test
    fun isSynced_returnsTrueWhenServerIdExistsAndStatusIsSynced() {
        val album = createAlbum(serverId = 1, syncStatus = SyncStatus.SYNCED)

        assertEquals(true, album.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenServerIdIsNull() {
        val album = createAlbum(serverId = null, syncStatus = SyncStatus.SYNCED)

        assertEquals(false, album.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsPendingCreate() {
        val album = createAlbum(serverId = 1, syncStatus = SyncStatus.PENDING_CREATE)

        assertEquals(false, album.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsPendingUpdate() {
        val album = createAlbum(serverId = 1, syncStatus = SyncStatus.PENDING_UPDATE)

        assertEquals(false, album.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsSyncing() {
        val album = createAlbum(serverId = 1, syncStatus = SyncStatus.SYNCING)

        assertEquals(false, album.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsFailed() {
        val album = createAlbum(serverId = 1, syncStatus = SyncStatus.FAILED)

        assertEquals(false, album.isSynced)
    }

    // displayCoverImage tests

    @Test
    fun displayCoverImage_returnsCoverImageUrlWhenAvailable() {
        val album = createAlbum(
            coverImageUrl = "/uploads/cover.jpg",
            coverImageLocalPath = "/local/cover.jpg"
        )

        assertEquals("/uploads/cover.jpg", album.displayCoverImage)
    }

    @Test
    fun displayCoverImage_returnsLocalPathWhenUrlIsNull() {
        val album = createAlbum(
            coverImageUrl = null,
            coverImageLocalPath = "/local/cover.jpg"
        )

        assertEquals("/local/cover.jpg", album.displayCoverImage)
    }

    @Test
    fun displayCoverImage_returnsNullWhenBothAreNull() {
        val album = createAlbum(
            coverImageUrl = null,
            coverImageLocalPath = null
        )

        assertNull(album.displayCoverImage)
    }
}
