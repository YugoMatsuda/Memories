package com.example.memoriesapp.ui.uilogics.viewmodels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import com.example.memoriesapp.repository.SyncQueueState
import com.example.memoriesapp.usecase.AlbumDisplayError
import com.example.memoriesapp.usecase.AlbumDisplayResult
import com.example.memoriesapp.usecase.AlbumListUseCaseWrapper
import com.example.memoriesapp.usecase.AlbumNextResult
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

/**
 * ViewModel for album list screen.
 */
class AlbumListViewModel(
    private val albumListUseCase: AlbumListUseCaseWrapper
) : ViewModel() {

    var userAvatarUrl by mutableStateOf<String?>(null)
        private set
    var displayResult by mutableStateOf<DisplayResult>(DisplayResult.Loading)
        private set
    var syncState by mutableStateOf(SyncQueueState(pendingCount = 0, isSyncing = false))
        private set
    var isOnline by mutableStateOf(true)
        private set

    val isNetworkDebugMode: Boolean = albumListUseCase.isNetworkDebugMode

    // Pagination state
    var isLoadingMore by mutableStateOf(false)
        private set

    private val _navigationEvent = MutableSharedFlow<NavigationEvent>()
    val navigationEvent: SharedFlow<NavigationEvent> = _navigationEvent.asSharedFlow()

    init {
        observeUser()
        observeAlbumChange()
        observeSync()
        observeOnlineState()
    }

    private fun observeUser() {
        albumListUseCase.observeUser()
            .onEach { user ->
                userAvatarUrl = user.displayAvatar
            }
            .launchIn(viewModelScope)
    }

    private fun observeAlbumChange() {
        albumListUseCase.observeAlbumChange()
            .onEach { event ->
                handleLocalChange(event)
            }
            .launchIn(viewModelScope)
    }

    private fun observeSync() {
        albumListUseCase.observeSync()
            .onEach { state ->
                syncState = state
            }
            .launchIn(viewModelScope)
    }

    private fun observeOnlineState() {
        albumListUseCase.observeOnlineState()
            .onEach { online ->
                isOnline = online
            }
            .launchIn(viewModelScope)
    }

    fun toggleOnlineState() {
        albumListUseCase.toggleOnlineState()
    }

    private fun handleLocalChange(event: LocalAlbumChangeEvent) {
        val currentData = (displayResult as? DisplayResult.Success)?.data ?: return
        val albums = currentData.albums.toMutableList()

        when (event) {
            is LocalAlbumChangeEvent.Created -> {
                albums.add(0, event.album)
            }
            is LocalAlbumChangeEvent.Updated -> {
                val index = albums.indexOfFirst { it.localId == event.album.localId }
                if (index >= 0) {
                    albums[index] = event.album
                }
            }
        }

        displayResult = DisplayResult.Success(
            makeListData(albums, currentData.currentPage, currentData.hasMore)
        )
    }

    fun onAppear() {
        if (displayResult is DisplayResult.Loading) {
            viewModelScope.launch {
                display()
            }
        }
    }

    fun onRefresh() {
        viewModelScope.launch {
            display()
        }
    }

    fun onLoadMore() {
        val currentData = (displayResult as? DisplayResult.Success)?.data ?: return
        if (!currentData.hasMore || isLoadingMore) return

        viewModelScope.launch {
            loadMore()
        }
    }

    fun onAlbumTap(album: Album) {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.AlbumDetail(album))
        }
    }

    fun showCreateAlbumForm() {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.CreateAlbum)
        }
    }

    fun showEditAlbumForm(album: Album) {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.EditAlbum(album))
        }
    }

    fun showUserProfile() {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.UserProfile)
        }
    }

    fun showSyncQueues() {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.SyncQueues)
        }
    }

    private suspend fun display() {
        displayResult = DisplayResult.Loading
        when (val result = albumListUseCase.display()) {
            is AlbumDisplayResult.Success -> {
                displayResult = DisplayResult.Success(
                    makeListData(result.pageInfo.albums, 1, result.pageInfo.hasMore)
                )
            }
            is AlbumDisplayResult.Failure -> {
                displayResult = DisplayResult.Failure(mapDisplayError(result.error))
            }
        }
    }

    private suspend fun loadMore() {
        val currentData = (displayResult as? DisplayResult.Success)?.data ?: return
        val previousCount = currentData.albums.size
        val nextPage = currentData.currentPage + 1

        isLoadingMore = true

        when (val result = albumListUseCase.next(nextPage)) {
            is AlbumNextResult.Success -> {
                displayResult = DisplayResult.Success(
                    makeListData(result.pageInfo.albums, nextPage, result.pageInfo.hasMore)
                )
                // If data didn't increase but hasMore is true, fetch next page automatically
                if (result.pageInfo.albums.size == previousCount && result.pageInfo.hasMore) {
                    loadMore()
                } else {
                    isLoadingMore = false
                }
            }
            is AlbumNextResult.Failure -> {
                isLoadingMore = false
            }
        }
    }

    private fun makeListData(albums: List<Album>, currentPage: Int, hasMore: Boolean): ListData {
        val items = albums.map { album ->
            AlbumItemUIModel(
                localId = album.localId.toString(),
                title = album.title,
                coverImageUrl = album.displayCoverImage,
                syncStatus = album.syncStatus
            )
        }
        return ListData(albums, items, currentPage, hasMore)
    }

    private fun mapDisplayError(error: AlbumDisplayError): ErrorUIModel {
        return when (error) {
            AlbumDisplayError.NETWORK_ERROR -> ErrorUIModel(
                message = "Network error. Please check your connection.",
                onRetry = { viewModelScope.launch { display() } }
            )
            AlbumDisplayError.OFFLINE -> ErrorUIModel(
                message = "You're offline and have no cached albums.",
                onRetry = { viewModelScope.launch { display() } }
            )
            AlbumDisplayError.UNKNOWN -> ErrorUIModel(
                message = "An unexpected error occurred.",
                onRetry = { viewModelScope.launch { display() } }
            )
        }
    }

    sealed class DisplayResult {
        data object Loading : DisplayResult()
        data class Success(val data: ListData) : DisplayResult()
        data class Failure(val error: ErrorUIModel) : DisplayResult()
    }

    data class ListData(
        val albums: List<Album>,
        val items: List<AlbumItemUIModel>,
        val currentPage: Int,
        val hasMore: Boolean
    )

    data class AlbumItemUIModel(
        val localId: String,
        val title: String,
        val coverImageUrl: String?,
        val syncStatus: SyncStatus
    )

    data class ErrorUIModel(
        val message: String,
        val onRetry: () -> Unit
    )

    sealed class NavigationEvent {
        data class AlbumDetail(val album: Album) : NavigationEvent()
        data object CreateAlbum : NavigationEvent()
        data class EditAlbum(val album: Album) : NavigationEvent()
        data object UserProfile : NavigationEvent()
        data object SyncQueues : NavigationEvent()
    }
}
