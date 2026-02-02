package com.example.memoriesapp.mapper

import com.example.memoriesapp.api.response.MemoryResponse
import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import com.example.memoriesapp.domain.Memory

/**
 * Mapper for Memory domain model
 */
object MemoryMapper {
    /**
     * Convert API response to domain model (generates new localId)
     */
    fun toDomain(response: MemoryResponse, albumLocalId: LocalId): Memory? {
        val imageUrl = response.imageLocalUri ?: response.imageRemoteUrl ?: return null

        return Memory(
            serverId = response.id,
            localId = LocalId.generate(),
            albumId = response.albumId,
            albumLocalId = albumLocalId,
            title = response.title,
            imageUrl = imageUrl,
            imageLocalPath = null,
            createdAt = parseTimestamp(response.createdAt),
            syncStatus = SyncStatus.SYNCED
        )
    }

    /**
     * Convert API response to domain model (preserves existing localId)
     */
    fun toDomain(response: MemoryResponse, localId: LocalId, albumLocalId: LocalId): Memory? {
        val imageUrl = response.imageLocalUri ?: response.imageRemoteUrl ?: return null

        return Memory(
            serverId = response.id,
            localId = localId,
            albumId = response.albumId,
            albumLocalId = albumLocalId,
            title = response.title,
            imageUrl = imageUrl,
            imageLocalPath = null,
            createdAt = parseTimestamp(response.createdAt),
            syncStatus = SyncStatus.SYNCED
        )
    }

    private fun parseTimestamp(dateString: String): Timestamp {
        return try {
            Timestamp.parse(dateString)
        } catch (e: Exception) {
            Timestamp.now()
        }
    }
}
