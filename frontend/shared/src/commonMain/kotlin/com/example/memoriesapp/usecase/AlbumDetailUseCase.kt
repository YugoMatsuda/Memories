package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.domain.Memory
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import com.example.memoriesapp.repository.LocalMemoryChangeEvent
import kotlinx.coroutines.flow.Flow

/**
 * Memory page info
 */
data class MemoryPageInfo(
    val memories: List<Memory>,
    val hasMore: Boolean
)

/**
 * Result of display memories operation
 */
sealed class MemoryDisplayResult {
    data class Success(val pageInfo: MemoryPageInfo) : MemoryDisplayResult()
    data class Failure(val error: MemoryDisplayError) : MemoryDisplayResult()
}

enum class MemoryDisplayError {
    OFFLINE,
    NETWORK_ERROR,
    UNKNOWN
}

/**
 * Result of next page operation for memories
 */
sealed class MemoryNextResult {
    data class Success(val pageInfo: MemoryPageInfo) : MemoryNextResult()
    data class Failure(val error: MemoryNextError) : MemoryNextResult()
}

enum class MemoryNextError {
    OFFLINE,
    NETWORK_ERROR,
    UNKNOWN
}

/**
 * Result of resolving an album by server ID
 */
sealed class ResolveAlbumResult {
    data class Success(val album: Album) : ResolveAlbumResult()
    data class Failure(val error: ResolveAlbumError) : ResolveAlbumResult()
}

enum class ResolveAlbumError {
    NOT_FOUND,
    NETWORK_ERROR,
    OFFLINE_UNAVAILABLE
}

interface AlbumDetailUseCase {
    val localChangeFlow: Flow<LocalMemoryChangeEvent>
    val observeAlbumUpdate: Flow<LocalAlbumChangeEvent>
    suspend fun display(album: Album): MemoryDisplayResult
    suspend fun next(album: Album, page: Int): MemoryNextResult
    suspend fun resolveAlbum(serverId: Int): ResolveAlbumResult
}
