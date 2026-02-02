package com.example.memoriesapp.mapper

import com.example.memoriesapp.api.response.UserResponse
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.domain.User
import kotlinx.datetime.LocalDate

/**
 * Mapper for User domain model
 */
object UserMapper {
    /**
     * Convert API response to domain model
     */
    fun toDomain(response: UserResponse): User {
        return User(
            id = response.id,
            name = response.name,
            username = response.username,
            birthday = response.birthday?.let { parseBirthday(it) },
            avatarUrl = response.avatarUrl,
            avatarLocalPath = null,
            syncStatus = SyncStatus.SYNCED
        )
    }

    private fun parseBirthday(dateString: String): LocalDate? {
        return try {
            LocalDate.parse(dateString)
        } catch (e: Exception) {
            null
        }
    }
}
