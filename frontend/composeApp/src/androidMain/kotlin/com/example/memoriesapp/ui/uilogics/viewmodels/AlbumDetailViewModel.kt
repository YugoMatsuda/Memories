package com.example.memoriesapp.ui.uilogics.viewmodels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.domain.Memory
import com.example.memoriesapp.repository.LocalAlbumChangeEvent
import com.example.memoriesapp.repository.LocalMemoryChangeEvent
import com.example.memoriesapp.usecase.AlbumDetailUseCase
import com.example.memoriesapp.usecase.MemoryDisplayError
import com.example.memoriesapp.usecase.MemoryDisplayResult
import com.example.memoriesapp.usecase.MemoryNextResult
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

/**
 * ViewModel for album detail screen.
 */
class AlbumDetailViewModel(
    private val initialAlbum: Album,
    private val albumDetailUseCase: AlbumDetailUseCase
) : ViewModel() {

    var album by mutableStateOf(initialAlbum)
        private set
    var displayResult by mutableStateOf<DisplayResult>(DisplayResult.Loading)
        private set
    var viewerMemoryId by mutableStateOf<String?>(null)
        private set

    // Pagination state
    var isLoadingMore by mutableStateOf(false)
        private set

    private val _navigationEvent = MutableSharedFlow<NavigationEvent>()
    val navigationEvent: SharedFlow<NavigationEvent> = _navigationEvent.asSharedFlow()

    init {
        observeMemoryChange()
        observeAlbumChange()
    }

    private fun observeMemoryChange() {
        albumDetailUseCase.localChangeFlow
            .onEach { event ->
                handleLocalMemoryChange(event)
            }
            .launchIn(viewModelScope)
    }

    private fun observeAlbumChange() {
        albumDetailUseCase.observeAlbumUpdate
            .onEach { event ->
                handleAlbumChange(event)
            }
            .launchIn(viewModelScope)
    }

    private fun handleLocalMemoryChange(event: LocalMemoryChangeEvent) {
        when (event) {
            is LocalMemoryChangeEvent.Created -> {
                if (event.memory.albumLocalId != album.localId) return
                val currentData = (displayResult as? DisplayResult.Success)?.data ?: return
                val memories = listOf(event.memory) + currentData.memories
                displayResult = DisplayResult.Success(
                    makeListData(memories, currentData.currentPage, currentData.hasMore)
                )
            }
        }
    }

    private fun handleAlbumChange(event: LocalAlbumChangeEvent) {
        when (event) {
            is LocalAlbumChangeEvent.Created -> {}
            is LocalAlbumChangeEvent.Updated -> {
                if (event.album.localId == album.localId) {
                    album = event.album
                }
            }
        }
    }

    fun updateAlbum(newAlbum: Album) {
        if (newAlbum.localId == album.localId) {
            album = newAlbum
        }
    }

    fun onAppear() {
        if (displayResult is DisplayResult.Loading) {
            viewModelScope.launch {
                display()
            }
        }
    }

    fun onLoadMore() {
        val currentData = (displayResult as? DisplayResult.Success)?.data ?: return
        if (!currentData.hasMore || isLoadingMore) return

        viewModelScope.launch {
            loadMore()
        }
    }

    fun showEditAlbumForm() {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.EditAlbum(album))
        }
    }

    fun showCreateMemoryForm() {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.CreateMemory(album))
        }
    }

    fun showMemoryViewer(memoryId: String) {
        viewerMemoryId = memoryId
    }

    fun closeMemoryViewer() {
        viewerMemoryId = null
    }

    fun navigateBack() {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.Back)
        }
    }

    private suspend fun display() {
        displayResult = DisplayResult.Loading
        when (val result = albumDetailUseCase.display(album)) {
            is MemoryDisplayResult.Success -> {
                displayResult = DisplayResult.Success(
                    makeListData(result.pageInfo.memories, 1, result.pageInfo.hasMore)
                )
            }
            is MemoryDisplayResult.Failure -> {
                displayResult = DisplayResult.Failure(mapDisplayError(result.error))
            }
        }
    }

    private suspend fun loadMore() {
        val currentData = (displayResult as? DisplayResult.Success)?.data ?: return
        val previousCount = currentData.memories.size
        val nextPage = currentData.currentPage + 1

        isLoadingMore = true

        when (val result = albumDetailUseCase.next(album, nextPage)) {
            is MemoryNextResult.Success -> {
                displayResult = DisplayResult.Success(
                    makeListData(result.pageInfo.memories, nextPage, result.pageInfo.hasMore)
                )
                // If data didn't increase but hasMore is true, fetch next page automatically
                if (result.pageInfo.memories.size == previousCount && result.pageInfo.hasMore) {
                    loadMore()
                } else {
                    isLoadingMore = false
                }
            }
            is MemoryNextResult.Failure -> {
                isLoadingMore = false
            }
        }
    }

    private fun makeListData(memories: List<Memory>, currentPage: Int, hasMore: Boolean): ListData {
        val items = memories.map { memory ->
            MemoryItemUIModel(
                localId = memory.localId.toString(),
                title = memory.title,
                displayImage = memory.displayImage,
                createdAt = memory.createdAt,
                syncStatus = memory.syncStatus
            )
        }
        return ListData(memories, items, currentPage, hasMore)
    }

    private fun mapDisplayError(error: MemoryDisplayError): ErrorUIModel {
        return when (error) {
            MemoryDisplayError.OFFLINE -> ErrorUIModel(
                message = "You are offline. No cached memories available.",
                onRetry = { viewModelScope.launch { display() } }
            )
            MemoryDisplayError.NETWORK_ERROR -> ErrorUIModel(
                message = "Network error. Please check your connection.",
                onRetry = { viewModelScope.launch { display() } }
            )
            MemoryDisplayError.UNKNOWN -> ErrorUIModel(
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
        val memories: List<Memory>,
        val items: List<MemoryItemUIModel>,
        val currentPage: Int,
        val hasMore: Boolean
    )

    data class MemoryItemUIModel(
        val localId: String,
        val title: String,
        val displayImage: String?,
        val createdAt: Timestamp,
        val syncStatus: SyncStatus
    )

    data class ErrorUIModel(
        val message: String,
        val onRetry: () -> Unit
    )

    sealed class NavigationEvent {
        data class EditAlbum(val album: Album) : NavigationEvent()
        data class CreateMemory(val album: Album) : NavigationEvent()
        data object Back : NavigationEvent()
    }
}
