package com.example.memoriesapp.domain

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MemoryTest {

    private val albumLocalId = LocalId.generate()

    private fun createMemory(
        serverId: Int? = 1,
        imageUrl: String? = "/uploads/image.jpg",
        imageLocalPath: String? = null,
        syncStatus: SyncStatus = SyncStatus.SYNCED
    ) = Memory(
        serverId = serverId,
        localId = LocalId.generate(),
        albumId = 1,
        albumLocalId = albumLocalId,
        title = "Test Memory",
        imageUrl = imageUrl,
        imageLocalPath = imageLocalPath,
        createdAt = Timestamp.now(),
        syncStatus = syncStatus
    )

    // isSynced tests

    @Test
    fun isSynced_returnsTrueWhenStatusIsSynced() {
        val memory = createMemory(syncStatus = SyncStatus.SYNCED)

        assertEquals(true, memory.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsPendingCreate() {
        val memory = createMemory(syncStatus = SyncStatus.PENDING_CREATE)

        assertEquals(false, memory.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsPendingUpdate() {
        val memory = createMemory(syncStatus = SyncStatus.PENDING_UPDATE)

        assertEquals(false, memory.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsSyncing() {
        val memory = createMemory(syncStatus = SyncStatus.SYNCING)

        assertEquals(false, memory.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsFailed() {
        val memory = createMemory(syncStatus = SyncStatus.FAILED)

        assertEquals(false, memory.isSynced)
    }

    @Test
    fun isSynced_returnsTrueEvenWhenServerIdIsNull() {
        // Memory.isSynced only checks syncStatus, not serverId
        val memory = createMemory(serverId = null, syncStatus = SyncStatus.SYNCED)

        assertEquals(true, memory.isSynced)
    }

    // displayImage tests

    @Test
    fun displayImage_returnsImageUrlWhenAvailable() {
        val memory = createMemory(
            imageUrl = "/uploads/image.jpg",
            imageLocalPath = "/local/image.jpg"
        )

        assertEquals("/uploads/image.jpg", memory.displayImage)
    }

    @Test
    fun displayImage_returnsLocalPathWhenUrlIsNull() {
        val memory = createMemory(
            imageUrl = null,
            imageLocalPath = "/local/image.jpg"
        )

        assertEquals("/local/image.jpg", memory.displayImage)
    }

    @Test
    fun displayImage_returnsNullWhenBothAreNull() {
        val memory = createMemory(
            imageUrl = null,
            imageLocalPath = null
        )

        assertNull(memory.displayImage)
    }
}
