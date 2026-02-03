package com.example.memoriesapp.mapper

import com.example.memoriesapp.api.response.AlbumResponse
import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import com.example.memoriesapp.domain.Album

/**
 * Mapper for Album domain model
 */
object AlbumMapper {
    /**
     * Convert API response to domain model (generates new localId)
     */
    fun toDomain(response: AlbumResponse): Album {
        return Album(
            serverId = response.id,
            localId = LocalId.generate(),
            title = response.title,
            coverImageUrl = response.coverImageUrl,
            coverImageLocalPath = null,
            createdAt = parseTimestamp(response.createdAt),
            syncStatus = SyncStatus.SYNCED
        )
    }

    /**
     * Convert API response to domain model (preserves existing localId)
     */
    fun toDomain(response: AlbumResponse, localId: LocalId): Album {
        return Album(
            serverId = response.id,
            localId = localId,
            title = response.title,
            coverImageUrl = response.coverImageUrl,
            coverImageLocalPath = null,
            createdAt = parseTimestamp(response.createdAt),
            syncStatus = SyncStatus.SYNCED
        )
    }

    private fun parseTimestamp(dateString: String): Timestamp {
        return try {
            // Backend returns datetime without 'Z' suffix, add it for proper parsing
            val isoString = if (dateString.endsWith("Z")) dateString else "${dateString}Z"
            Timestamp.parse(isoString)
        } catch (e: Exception) {
            Timestamp.now()
        }
    }
}
