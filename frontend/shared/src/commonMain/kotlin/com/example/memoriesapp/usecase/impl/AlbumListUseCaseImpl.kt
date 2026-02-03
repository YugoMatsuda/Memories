package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.domain.User
import com.example.memoriesapp.gateway.AlbumGateway
import com.example.memoriesapp.mapper.AlbumMapper
import com.example.memoriesapp.repository.AlbumRepository
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import com.example.memoriesapp.repository.ReachabilityRepository
import com.example.memoriesapp.repository.SyncQueueRepository
import com.example.memoriesapp.repository.SyncQueueState
import com.example.memoriesapp.repository.UserRepository
import com.example.memoriesapp.usecase.AlbumDisplayError
import com.example.memoriesapp.usecase.AlbumDisplayResult
import com.example.memoriesapp.usecase.AlbumListUseCase
import com.example.memoriesapp.usecase.AlbumNextError
import com.example.memoriesapp.usecase.AlbumNextResult
import com.example.memoriesapp.usecase.AlbumPageInfo
import com.example.memoriesapp.usecase.SyncQueueService
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.merge
import kotlinx.coroutines.flow.onEach

/**
 * UseCase for album list screen
 */
@OptIn(ExperimentalCoroutinesApi::class)
class AlbumListUseCaseImpl(
    private val userRepository: UserRepository,
    private val albumRepository: AlbumRepository,
    private val albumGateway: AlbumGateway,
    private val reachabilityRepository: ReachabilityRepository,
    private val syncQueueService: SyncQueueService,
    private val syncQueueRepository: SyncQueueRepository
) : AlbumListUseCase {
    companion object {
        private const val PAGE_SIZE = 5
    }

    override fun observeUser(): Flow<User> = userRepository.userFlow

    override fun observeAlbumChange(): Flow<LocalAlbumChangeEvent> = albumRepository.localChangeFlow

    override fun observeSync(): Flow<SyncQueueState> = merge(
        syncQueueRepository.stateFlow,
        reachabilityRepository.isConnectedFlow
            .distinctUntilChanged()
            .filter { it }
            .onEach { syncQueueService.processQueue() }
            .flatMapLatest { emptyFlow() }
    )

    override fun observeOnlineState(): Flow<Boolean> = reachabilityRepository.isConnectedFlow

    override suspend fun display(): AlbumDisplayResult {
        return if (reachabilityRepository.isConnected) {
            try {
                val response = albumGateway.getAlbums(page = 1, pageSize = PAGE_SIZE)
                val albums = response.items.map { AlbumMapper.toDomain(it) }
                albumRepository.syncSet(albums)
                // Return albums from cache to get preserved localIds, limited to current page
                val cachedAlbums = albumRepository.getAll().take(PAGE_SIZE)
                val hasMore = response.page * response.pageSize < response.total
                AlbumDisplayResult.Success(AlbumPageInfo(cachedAlbums, hasMore))
            } catch (e: Exception) {
                // Fallback to all cache on error
                val cached = albumRepository.getAll()
                if (cached.isNotEmpty()) {
                    AlbumDisplayResult.Success(AlbumPageInfo(cached, hasMore = false))
                } else {
                    AlbumDisplayResult.Failure(mapDisplayError(e))
                }
            }
        } else {
            // Offline: get all from cache
            val cached = albumRepository.getAll()
            if (cached.isEmpty()) {
                AlbumDisplayResult.Failure(AlbumDisplayError.OFFLINE)
            } else {
                AlbumDisplayResult.Success(AlbumPageInfo(cached, hasMore = false))
            }
        }
    }

    override suspend fun next(page: Int): AlbumNextResult {
        // Pagination requires online
        if (!reachabilityRepository.isConnected) {
            return AlbumNextResult.Failure(AlbumNextError.OFFLINE)
        }

        return try {
            val response = albumGateway.getAlbums(page = page, pageSize = PAGE_SIZE)
            val albums = response.items.map { AlbumMapper.toDomain(it) }
            albumRepository.syncAppend(albums)
            // Limit to current cumulative page count
            val allAlbums = albumRepository.getAll().take(page * PAGE_SIZE)
            val hasMore = response.page * response.pageSize < response.total
            AlbumNextResult.Success(AlbumPageInfo(allAlbums, hasMore))
        } catch (e: Exception) {
            AlbumNextResult.Failure(mapNextError(e))
        }
    }

    private fun mapDisplayError(error: Exception): AlbumDisplayError {
        // Simple network error detection
        return if (error.message?.contains("network", ignoreCase = true) == true ||
            error.message?.contains("connection", ignoreCase = true) == true) {
            AlbumDisplayError.NETWORK_ERROR
        } else {
            AlbumDisplayError.UNKNOWN
        }
    }

    private fun mapNextError(error: Exception): AlbumNextError {
        return if (error.message?.contains("network", ignoreCase = true) == true ||
            error.message?.contains("connection", ignoreCase = true) == true) {
            AlbumNextError.NETWORK_ERROR
        } else {
            AlbumNextError.UNKNOWN
        }
    }
}
