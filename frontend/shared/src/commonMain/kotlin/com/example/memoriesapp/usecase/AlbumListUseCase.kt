package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import com.example.memoriesapp.repository.SyncQueueState
import kotlinx.coroutines.flow.Flow

/**
 * Page info containing albums and pagination state
 */
data class AlbumPageInfo(
    val albums: List<Album>,
    val hasMore: Boolean
)

/**
 * Result of display operation
 */
sealed class AlbumDisplayResult {
    data class Success(val pageInfo: AlbumPageInfo) : AlbumDisplayResult()
    data class Failure(val error: AlbumDisplayError) : AlbumDisplayResult()
}

enum class AlbumDisplayError {
    NETWORK_ERROR,
    OFFLINE,
    UNKNOWN
}

/**
 * Result of next page operation
 */
sealed class AlbumNextResult {
    data class Success(val pageInfo: AlbumPageInfo) : AlbumNextResult()
    data class Failure(val error: AlbumNextError) : AlbumNextResult()
}

enum class AlbumNextError {
    NETWORK_ERROR,
    OFFLINE,
    UNKNOWN
}

interface AlbumListUseCase {
    fun observeUser(): Flow<User>
    fun observeAlbumChange(): Flow<LocalAlbumChangeEvent>
    fun observeSync(): Flow<SyncQueueState>
    fun observeOnlineState(): Flow<Boolean>
    suspend fun display(): AlbumDisplayResult
    suspend fun next(page: Int): AlbumNextResult
}
