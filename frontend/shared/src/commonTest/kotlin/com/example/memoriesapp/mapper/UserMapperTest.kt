package com.example.memoriesapp.mapper

import com.example.memoriesapp.api.response.UserResponse
import com.example.memoriesapp.core.SyncStatus
import kotlinx.datetime.LocalDate
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class UserMapperTest {

    @Test
    fun toDomain_mapsBasicFields() {
        val response = UserResponse(
            id = 1,
            name = "Demo User",
            username = "demo",
            birthday = "1990-05-15",
            avatarUrl = "/uploads/avatar.jpg"
        )

        val user = UserMapper.toDomain(response)

        assertEquals(1, user.id)
        assertEquals("Demo User", user.name)
        assertEquals("demo", user.username)
        assertEquals(LocalDate(1990, 5, 15), user.birthday)
        assertEquals("/uploads/avatar.jpg", user.avatarUrl)
        assertNull(user.avatarLocalPath)
        assertEquals(SyncStatus.SYNCED, user.syncStatus)
    }

    @Test
    fun toDomain_withNullBirthday() {
        val response = UserResponse(
            id = 2,
            name = "Test User",
            username = "test",
            birthday = null,
            avatarUrl = "/uploads/avatar.jpg"
        )

        val user = UserMapper.toDomain(response)

        assertNull(user.birthday)
    }

    @Test
    fun toDomain_withNullAvatarUrl() {
        val response = UserResponse(
            id = 3,
            name = "No Avatar User",
            username = "noavatar",
            birthday = "2000-01-01",
            avatarUrl = null
        )

        val user = UserMapper.toDomain(response)

        assertNull(user.avatarUrl)
        assertNull(user.displayAvatar)
    }

    @Test
    fun toDomain_withAllNullOptionalFields() {
        val response = UserResponse(
            id = 4,
            name = "Minimal User",
            username = "minimal",
            birthday = null,
            avatarUrl = null
        )

        val user = UserMapper.toDomain(response)

        assertEquals(4, user.id)
        assertEquals("Minimal User", user.name)
        assertEquals("minimal", user.username)
        assertNull(user.birthday)
        assertNull(user.avatarUrl)
    }

    @Test
    fun toDomain_handlesInvalidBirthdayFormat() {
        val response = UserResponse(
            id = 5,
            name = "Invalid Birthday User",
            username = "invalidbday",
            birthday = "invalid-date",
            avatarUrl = null
        )

        // Should not throw, birthday falls back to null
        val user = UserMapper.toDomain(response)

        assertNull(user.birthday)
    }

    @Test
    fun toDomain_parsesValidBirthday() {
        val response = UserResponse(
            id = 6,
            name = "Valid Birthday User",
            username = "validbday",
            birthday = "1985-12-25",
            avatarUrl = null
        )

        val user = UserMapper.toDomain(response)

        assertEquals(LocalDate(1985, 12, 25), user.birthday)
    }

    @Test
    fun toDomain_setsStatusToSynced() {
        val response = UserResponse(
            id = 1,
            name = "Test",
            username = "test"
        )

        val user = UserMapper.toDomain(response)

        assertEquals(SyncStatus.SYNCED, user.syncStatus)
        assertEquals(true, user.isSynced)
    }
}
