package com.example.memoriesapp.ui.uilogics.viewmodels

import android.graphics.Bitmap
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.usecase.AlbumCreateResult
import com.example.memoriesapp.usecase.AlbumFormUseCase
import com.example.memoriesapp.usecase.AlbumUpdateResult
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import java.io.ByteArrayOutputStream

sealed class AlbumFormMode {
    data object Create : AlbumFormMode()
    data class Edit(val album: Album) : AlbumFormMode()
}

class AlbumFormViewModel(
    private val mode: AlbumFormMode,
    private val albumFormUseCase: AlbumFormUseCase
) : ViewModel() {

    var title by mutableStateOf("")
        private set
    var coverImage by mutableStateOf<CoverImageState>(CoverImageState.None)
        private set
    var isSaving by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set

    private val _navigationEvent = MutableSharedFlow<NavigationEvent>()
    val navigationEvent: SharedFlow<NavigationEvent> = _navigationEvent.asSharedFlow()

    val navigationTitle: String
        get() = when (mode) {
            is AlbumFormMode.Create -> "New Album"
            is AlbumFormMode.Edit -> "Edit Album"
        }

    val isValid: Boolean
        get() = title.trim().isNotEmpty()

    init {
        when (mode) {
            is AlbumFormMode.Create -> {
                title = ""
                coverImage = CoverImageState.None
            }
            is AlbumFormMode.Edit -> {
                title = mode.album.title
                coverImage = mode.album.displayCoverImage?.let {
                    CoverImageState.Uploaded(it)
                } ?: CoverImageState.None
            }
        }
    }

    fun onTitleChange(newTitle: String) {
        title = newTitle
    }

    fun onImageSelected(bitmap: Bitmap) {
        coverImage = CoverImageState.Selected(bitmap)
    }

    fun save() {
        viewModelScope.launch {
            saveAlbum()
        }
    }

    fun cancel() {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.Dismiss(updatedAlbum = null))
        }
    }

    fun clearError() {
        errorMessage = null
    }

    private suspend fun saveAlbum() {
        isSaving = true
        errorMessage = null

        val imageData: ByteArray? = when (val image = coverImage) {
            is CoverImageState.Selected -> {
                val stream = ByteArrayOutputStream()
                image.bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream)
                stream.toByteArray()
            }
            else -> null
        }

        when (mode) {
            is AlbumFormMode.Create -> createAlbum(imageData)
            is AlbumFormMode.Edit -> updateAlbum(mode.album, imageData)
        }

        isSaving = false
    }

    private suspend fun createAlbum(imageData: ByteArray?) {
        when (val result = albumFormUseCase.createAlbum(title.trim(), imageData)) {
            is AlbumCreateResult.Success,
            is AlbumCreateResult.SuccessPendingSync -> {
                _navigationEvent.emit(NavigationEvent.Dismiss(updatedAlbum = null))
            }
            is AlbumCreateResult.Failure -> {
                errorMessage = mapCreateError(result.error)
            }
        }
    }

    private suspend fun updateAlbum(album: Album, imageData: ByteArray?) {
        when (val result = albumFormUseCase.updateAlbum(album, title.trim(), imageData)) {
            is AlbumUpdateResult.Success -> {
                _navigationEvent.emit(NavigationEvent.Dismiss(updatedAlbum = result.album))
            }
            is AlbumUpdateResult.SuccessPendingSync -> {
                _navigationEvent.emit(NavigationEvent.Dismiss(updatedAlbum = result.album))
            }
            is AlbumUpdateResult.Failure -> {
                errorMessage = mapUpdateError(result.error)
            }
        }
    }

    private fun mapCreateError(error: com.example.memoriesapp.usecase.AlbumCreateError): String {
        return when (error) {
            com.example.memoriesapp.usecase.AlbumCreateError.NETWORK_ERROR ->
                "Network error. Please check your connection and try again."
            com.example.memoriesapp.usecase.AlbumCreateError.SERVER_ERROR ->
                "Server error. Please try again later."
            com.example.memoriesapp.usecase.AlbumCreateError.IMAGE_STORAGE_FAILED ->
                "Failed to save the image locally. Please try again."
            com.example.memoriesapp.usecase.AlbumCreateError.DATABASE_ERROR ->
                "Failed to save to local database. Please try again."
            else -> "An unexpected error occurred. Please try again."
        }
    }

    private fun mapUpdateError(error: com.example.memoriesapp.usecase.AlbumUpdateError): String {
        return when (error) {
            com.example.memoriesapp.usecase.AlbumUpdateError.NETWORK_ERROR ->
                "Network error. Please check your connection and try again."
            com.example.memoriesapp.usecase.AlbumUpdateError.SERVER_ERROR ->
                "Server error. Please try again later."
            com.example.memoriesapp.usecase.AlbumUpdateError.NOT_FOUND ->
                "Album not found. It may have been deleted."
            com.example.memoriesapp.usecase.AlbumUpdateError.IMAGE_STORAGE_FAILED ->
                "Failed to save the image locally. Please try again."
            com.example.memoriesapp.usecase.AlbumUpdateError.DATABASE_ERROR ->
                "Failed to save to local database. Please try again."
            else -> "An unexpected error occurred. Please try again."
        }
    }

    sealed class CoverImageState {
        data object None : CoverImageState()
        data class Uploaded(val url: String) : CoverImageState()
        data class Selected(val bitmap: Bitmap) : CoverImageState()
    }

    sealed class NavigationEvent {
        data class Dismiss(val updatedAlbum: Album? = null) : NavigationEvent()
    }
}
