package com.example.memoriesapp.repository.mock

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.repository.AlbumRepository
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow

class MockAlbumRepository : AlbumRepository {
    private val albums = mutableListOf<Album>()
    private val _localChangeFlow = MutableSharedFlow<LocalAlbumChangeEvent>()

    override val localChangeFlow: Flow<LocalAlbumChangeEvent> = _localChangeFlow

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
        albums.forEach { newAlbum ->
            val existingIndex = this.albums.indexOfFirst { it.serverId == newAlbum.serverId }
            if (existingIndex >= 0) {
                this.albums[existingIndex] = newAlbum
            } else {
                this.albums.add(newAlbum)
            }
        }
    }

    override suspend fun insert(album: Album) {
        albums.add(album)
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
            albums[index] = albums[index].copy(serverId = serverId)
        }
    }

    override suspend fun updateCoverImageUrl(localId: LocalId, url: String) {
        val index = albums.indexOfFirst { it.localId == localId }
        if (index >= 0) {
            albums[index] = albums[index].copy(coverImageUrl = url)
        }
    }

    // Test helpers
    fun setAlbums(albums: List<Album>) {
        this.albums.clear()
        this.albums.addAll(albums)
    }

    fun getAlbums(): List<Album> = albums.toList()
}
