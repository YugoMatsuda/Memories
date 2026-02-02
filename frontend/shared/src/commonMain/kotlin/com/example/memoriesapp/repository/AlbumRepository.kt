package com.example.memoriesapp.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.Album
import kotlinx.coroutines.flow.Flow

/**
 * Event fired when a local album change occurs
 */
sealed class LocalAlbumChangeEvent {
    data class Created(val album: Album) : LocalAlbumChangeEvent()
    data class Updated(val album: Album) : LocalAlbumChangeEvent()
}

/**
 * Repository interface for Album data
 */
interface AlbumRepository {
    // Read
    suspend fun getAll(): List<Album>
    suspend fun getByLocalId(localId: LocalId): Album?
    suspend fun getByServerId(serverId: Int): Album?

    // Server Sync (no event firing)
    suspend fun syncSet(albums: List<Album>)
    suspend fun syncAppend(albums: List<Album>)

    // Local Operations (fires events)
    suspend fun insert(album: Album)
    suspend fun update(album: Album)
    suspend fun delete(localId: LocalId)

    // Sync Status
    suspend fun markAsSynced(localId: LocalId, serverId: Int)
    suspend fun updateCoverImageUrl(localId: LocalId, url: String)

    // Change Flow
    val localChangeFlow: Flow<LocalAlbumChangeEvent>
}
