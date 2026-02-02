package com.example.memoriesapp.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.Album
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * Callback interface for album change events (implemented by Swift)
 */
interface AlbumChangeCallback {
    fun onCreated(album: Album)
    fun onUpdated(album: Album)
}

/**
 * Bridge interface for Swift to implement
 */
interface AlbumRepositoryBridge {
    // Read
    suspend fun getAll(): List<Album>
    suspend fun getByLocalId(localId: LocalId): Album?
    suspend fun getByServerId(serverId: Int): Album?

    // Server Sync
    suspend fun syncSet(albums: List<Album>)
    suspend fun syncAppend(albums: List<Album>)

    // Local Operations
    suspend fun insert(album: Album)
    suspend fun update(album: Album)
    suspend fun delete(localId: LocalId)

    // Sync Status
    suspend fun markAsSynced(localId: LocalId, serverId: Int)
    suspend fun updateCoverImageUrl(localId: LocalId, url: String)

    // Change observation - Swift calls the callback when changes occur
    fun registerChangeCallback(callback: AlbumChangeCallback)
    fun unregisterChangeCallback()
}

/**
 * iOS implementation of AlbumRepository that bridges to Swift
 */
class AlbumRepositoryImpl(
    private val bridge: AlbumRepositoryBridge
) : AlbumRepository {

    private val _localChangeFlow = MutableSharedFlow<LocalAlbumChangeEvent>(
        extraBufferCapacity = 64,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )

    override val localChangeFlow: SharedFlow<LocalAlbumChangeEvent> = _localChangeFlow.asSharedFlow()

    init {
        bridge.registerChangeCallback(object : AlbumChangeCallback {
            override fun onCreated(album: Album) {
                _localChangeFlow.tryEmit(LocalAlbumChangeEvent.Created(album))
            }
            override fun onUpdated(album: Album) {
                _localChangeFlow.tryEmit(LocalAlbumChangeEvent.Updated(album))
            }
        })
    }

    override suspend fun getAll(): List<Album> = bridge.getAll()

    override suspend fun getByLocalId(localId: LocalId): Album? = bridge.getByLocalId(localId)

    override suspend fun getByServerId(serverId: Int): Album? = bridge.getByServerId(serverId)

    override suspend fun syncSet(albums: List<Album>) = bridge.syncSet(albums)

    override suspend fun syncAppend(albums: List<Album>) = bridge.syncAppend(albums)

    override suspend fun insert(album: Album) = bridge.insert(album)

    override suspend fun update(album: Album) = bridge.update(album)

    override suspend fun delete(localId: LocalId) = bridge.delete(localId)

    override suspend fun markAsSynced(localId: LocalId, serverId: Int) =
        bridge.markAsSynced(localId, serverId)

    override suspend fun updateCoverImageUrl(localId: LocalId, url: String) =
        bridge.updateCoverImageUrl(localId, url)
}
