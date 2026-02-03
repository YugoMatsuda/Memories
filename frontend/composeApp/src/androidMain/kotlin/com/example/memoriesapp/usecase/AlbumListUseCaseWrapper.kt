package com.example.memoriesapp.usecase

import com.example.memoriesapp.data.repository.DebugReachabilityRepository
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import com.example.memoriesapp.repository.ReachabilityRepository
import com.example.memoriesapp.repository.SyncQueueState
import com.example.memoriesapp.usecase.AlbumDisplayResult
import com.example.memoriesapp.usecase.AlbumListUseCase
import com.example.memoriesapp.usecase.AlbumNextResult
import kotlinx.coroutines.flow.Flow

/**
 * Wrapper for AlbumListUseCase that adds debug functionality.
 * Similar to iOS AlbumListUseCaseAdapter.
 */
class AlbumListUseCaseWrapper(
    private val useCase: AlbumListUseCase,
    private val reachabilityRepository: ReachabilityRepository
) : AlbumListUseCase {

    val isNetworkDebugMode: Boolean
        get() = reachabilityRepository is DebugReachabilityRepository

    fun toggleOnlineState() {
        val debugRepository = reachabilityRepository as? DebugReachabilityRepository
            ?: error("toggleOnlineState can only be called with DebugReachabilityRepository")
        debugRepository.setOnline(!debugRepository.isConnected)
    }

    // Delegate all UseCase methods

    override fun observeUser(): Flow<User> = useCase.observeUser()

    override fun observeAlbumChange(): Flow<LocalAlbumChangeEvent> = useCase.observeAlbumChange()

    override fun observeSync(): Flow<SyncQueueState> = useCase.observeSync()

    override fun observeOnlineState(): Flow<Boolean> = useCase.observeOnlineState()

    override suspend fun display(): AlbumDisplayResult = useCase.display()

    override suspend fun next(page: Int): AlbumNextResult = useCase.next(page)
}
