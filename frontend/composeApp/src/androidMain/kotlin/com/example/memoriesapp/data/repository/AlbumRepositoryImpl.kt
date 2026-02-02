package com.example.memoriesapp.data.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.repository.AlbumRepository
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * In-memory implementation of AlbumRepository.
 * No persistence - data is lost on app restart.
 */
class AlbumRepositoryImpl : AlbumRepository {
    private val albums = mutableListOf<Album>()
    private val _localChangeFlow = MutableSharedFlow<LocalAlbumChangeEvent>()

    override val localChangeFlow: Flow<LocalAlbumChangeEvent> = _localChangeFlow.asSharedFlow()

    override suspend fun getAll(): List<Album> = albums.toList()

    override suspend fun getByLocalId(localId: LocalId): Album? =
        albums.find { it.localId == localId }

    override suspend fun getByServerId(serverId: Int): Album? =
        albums.find { it.serverId == serverId }

    override suspend fun syncSet(albums: List<Album>) {
        this.albums.clear()
        this.albums.addAll(albums)
    }

    override suspend fun syncAppend(albums: List<Album>) {
        albums.forEach { album ->
            val index = this.albums.indexOfFirst { it.localId == album.localId }
            if (index >= 0) {
                this.albums[index] = album
            } else {
                this.albums.add(album)
            }
        }
    }

    override suspend fun insert(album: Album) {
        albums.add(0, album)
        _localChangeFlow.emit(LocalAlbumChangeEvent.Created(album))
    }

    override suspend fun update(album: Album) {
        val index = albums.indexOfFirst { it.localId == album.localId }
        if (index >= 0) {
            albums[index] = album
            _localChangeFlow.emit(LocalAlbumChangeEvent.Updated(album))
        }
    }

    override suspend fun delete(localId: LocalId) {
        albums.removeAll { it.localId == localId }
    }

    override suspend fun markAsSynced(localId: LocalId, serverId: Int) {
        val index = albums.indexOfFirst { it.localId == localId }
        if (index >= 0) {
            albums[index] = albums[index].copy(
                serverId = serverId,
                syncStatus = SyncStatus.SYNCED
            )
        }
    }

    override suspend fun updateCoverImageUrl(localId: LocalId, url: String) {
        val index = albums.indexOfFirst { it.localId == localId }
        if (index >= 0) {
            albums[index] = albums[index].copy(coverImageUrl = url)
        }
    }
}
