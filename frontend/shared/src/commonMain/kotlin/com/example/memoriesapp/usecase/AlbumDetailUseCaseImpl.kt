package com.example.memoriesapp.usecase

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.domain.Memory
import com.example.memoriesapp.gateway.AlbumGateway
import com.example.memoriesapp.gateway.MemoryGateway
import com.example.memoriesapp.mapper.AlbumMapper
import com.example.memoriesapp.mapper.MemoryMapper
import com.example.memoriesapp.repository.AlbumRepository
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import com.example.memoriesapp.repository.LocalMemoryChangeEvent
import com.example.memoriesapp.repository.MemoryRepository
import com.example.memoriesapp.repository.ReachabilityRepository
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

/**
 * UseCase for album detail screen
 */
class AlbumDetailUseCaseImpl(
    private val memoryRepository: MemoryRepository,
    private val albumRepository: AlbumRepository,
    private val albumGateway: AlbumGateway,
    private val memoryGateway: MemoryGateway,
    private val reachabilityRepository: ReachabilityRepository
) : AlbumDetailUseCase {
    companion object {
        private const val PAGE_SIZE = 5
    }

    override val localChangeFlow: Flow<LocalMemoryChangeEvent>
        get() = memoryRepository.localChangeFlow

    override val observeAlbumUpdate: Flow<LocalAlbumChangeEvent>
        get() = albumRepository.localChangeFlow

    override suspend fun display(album: Album): MemoryDisplayResult {
        // If album is not synced yet, only show local memories (all of them)
        val albumServerId = album.serverId
        if (albumServerId == null) {
            val cached = memoryRepository.getAll(album.localId)
            return MemoryDisplayResult.Success(MemoryPageInfo(cached, hasMore = false))
        }

        return if (reachabilityRepository.isConnected) {
            try {
                val response = memoryGateway.getMemories(albumId = albumServerId, page = 1, pageSize = PAGE_SIZE)
                val memories = response.items.mapNotNull { MemoryMapper.toDomain(it, album.localId) }
                try {
                    memoryRepository.syncSet(memories, album.localId)
                } catch (_: Exception) {}
                // Limit to current page
                val allMemories = memoryRepository.getAll(album.localId).take(PAGE_SIZE)
                val hasMore = response.page * response.pageSize < response.total
                MemoryDisplayResult.Success(MemoryPageInfo(allMemories, hasMore))
            } catch (e: Exception) {
                // Fallback to all cache on error
                val cached = memoryRepository.getAll(album.localId)
                if (cached.isNotEmpty()) {
                    MemoryDisplayResult.Success(MemoryPageInfo(cached, hasMore = false))
                } else {
                    MemoryDisplayResult.Failure(mapDisplayError(e))
                }
            }
        } else {
            // Offline: get all from cache (empty is valid)
            val cached = memoryRepository.getAll(album.localId)
            MemoryDisplayResult.Success(MemoryPageInfo(cached, hasMore = false))
        }
    }

    override suspend fun next(album: Album, page: Int): MemoryNextResult {
        // Pagination requires online and synced album
        if (!reachabilityRepository.isConnected) {
            return MemoryNextResult.Failure(MemoryNextError.OFFLINE)
        }

        val albumServerId = album.serverId
            ?: return MemoryNextResult.Failure(MemoryNextError.OFFLINE)

        return try {
            val response = memoryGateway.getMemories(albumId = albumServerId, page = page, pageSize = PAGE_SIZE)
            val memories = response.items.mapNotNull { MemoryMapper.toDomain(it, album.localId) }
            try {
                memoryRepository.syncAppend(memories)
            } catch (_: Exception) {}
            // Limit to current cumulative page count
            val allMemories = memoryRepository.getAll(album.localId).take(page * PAGE_SIZE)
            val hasMore = response.page * response.pageSize < response.total
            MemoryNextResult.Success(MemoryPageInfo(allMemories, hasMore))
        } catch (e: Exception) {
            MemoryNextResult.Failure(mapNextError(e))
        }
    }

    override suspend fun resolveAlbum(serverId: Int): ResolveAlbumResult {
        return if (reachabilityRepository.isConnected) {
            try {
                val response = albumGateway.getAlbum(id = serverId)
                val album = AlbumMapper.toDomain(response)
                try {
                    albumRepository.syncSet(listOf(album))
                } catch (_: Exception) {}
                // Return from cache to get preserved localId
                val cachedAlbum = albumRepository.getByServerId(serverId)
                ResolveAlbumResult.Success(cachedAlbum ?: album)
            } catch (e: ApiError) {
                when (e) {
                    is ApiError.NotFound -> ResolveAlbumResult.Failure(ResolveAlbumError.NOT_FOUND)
                    is ApiError.NetworkError -> ResolveAlbumResult.Failure(ResolveAlbumError.NETWORK_ERROR)
                    else -> ResolveAlbumResult.Failure(ResolveAlbumError.NOT_FOUND)
                }
            } catch (e: Exception) {
                ResolveAlbumResult.Failure(ResolveAlbumError.NOT_FOUND)
            }
        } else {
            // Offline: try cache
            val cachedAlbum = albumRepository.getByServerId(serverId)
            if (cachedAlbum != null) {
                ResolveAlbumResult.Success(cachedAlbum)
            } else {
                ResolveAlbumResult.Failure(ResolveAlbumError.OFFLINE_UNAVAILABLE)
            }
        }
    }

    private fun mapDisplayError(error: Exception): MemoryDisplayError {
        return if (error.message?.contains("network", ignoreCase = true) == true) {
            MemoryDisplayError.NETWORK_ERROR
        } else {
            MemoryDisplayError.UNKNOWN
        }
    }

    private fun mapNextError(error: Exception): MemoryNextError {
        return if (error.message?.contains("network", ignoreCase = true) == true) {
            MemoryNextError.NETWORK_ERROR
        } else {
            MemoryNextError.UNKNOWN
        }
    }
}
