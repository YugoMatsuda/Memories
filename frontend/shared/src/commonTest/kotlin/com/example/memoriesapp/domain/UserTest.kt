package com.example.memoriesapp.domain

import com.example.memoriesapp.core.SyncStatus
import kotlinx.datetime.LocalDate
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class UserTest {

    private fun createUser(
        avatarUrl: String? = null,
        avatarLocalPath: String? = null,
        syncStatus: SyncStatus = SyncStatus.SYNCED
    ) = User(
        id = 1,
        name = "Test User",
        username = "testuser",
        birthday = LocalDate(1990, 1, 1),
        avatarUrl = avatarUrl,
        avatarLocalPath = avatarLocalPath,
        syncStatus = syncStatus
    )

    // isSynced tests

    @Test
    fun isSynced_returnsTrueWhenStatusIsSynced() {
        val user = createUser(syncStatus = SyncStatus.SYNCED)

        assertEquals(true, user.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsPendingCreate() {
        val user = createUser(syncStatus = SyncStatus.PENDING_CREATE)

        assertEquals(false, user.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsPendingUpdate() {
        val user = createUser(syncStatus = SyncStatus.PENDING_UPDATE)

        assertEquals(false, user.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsSyncing() {
        val user = createUser(syncStatus = SyncStatus.SYNCING)

        assertEquals(false, user.isSynced)
    }

    @Test
    fun isSynced_returnsFalseWhenStatusIsFailed() {
        val user = createUser(syncStatus = SyncStatus.FAILED)

        assertEquals(false, user.isSynced)
    }

    // displayAvatar tests

    @Test
    fun displayAvatar_returnsAvatarUrlWhenAvailable() {
        val user = createUser(
            avatarUrl = "/uploads/avatar.jpg",
            avatarLocalPath = "/local/avatar.jpg"
        )

        assertEquals("/uploads/avatar.jpg", user.displayAvatar)
    }

    @Test
    fun displayAvatar_returnsLocalPathWhenUrlIsNull() {
        val user = createUser(
            avatarUrl = null,
            avatarLocalPath = "/local/avatar.jpg"
        )

        assertEquals("/local/avatar.jpg", user.displayAvatar)
    }

    @Test
    fun displayAvatar_returnsNullWhenBothAreNull() {
        val user = createUser(
            avatarUrl = null,
            avatarLocalPath = null
        )

        assertNull(user.displayAvatar)
    }
}
