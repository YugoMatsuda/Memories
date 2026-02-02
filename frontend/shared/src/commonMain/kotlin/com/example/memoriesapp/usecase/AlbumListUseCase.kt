package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.User
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import com.example.memoriesapp.repository.SyncQueueState
import kotlinx.coroutines.flow.Flow

interface AlbumListUseCase {
    fun observeUser(): Flow<User>
    fun observeAlbumChange(): Flow<LocalAlbumChangeEvent>
    fun observeSync(): Flow<SyncQueueState>
    fun observeOnlineState(): Flow<Boolean>
    suspend fun display(): AlbumDisplayResult
    suspend fun next(page: Int): AlbumNextResult
}
