package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import com.example.memoriesapp.repository.LocalMemoryChangeEvent
import kotlinx.coroutines.flow.Flow

interface AlbumDetailUseCase {
    val localChangeFlow: Flow<LocalMemoryChangeEvent>
    val observeAlbumUpdate: Flow<LocalAlbumChangeEvent>
    suspend fun display(album: Album): MemoryDisplayResult
    suspend fun next(album: Album, page: Int): MemoryNextResult
    suspend fun resolveAlbum(serverId: Int): ResolveAlbumResult
}
