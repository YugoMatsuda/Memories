package com.example.memoriesapp.ui.uilogics.viewmodels

import android.graphics.Bitmap
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.usecase.MemoryCreateResult
import com.example.memoriesapp.usecase.MemoryFormUseCase
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import java.io.ByteArrayOutputStream

class MemoryFormViewModel(
    private val album: Album,
    private val memoryFormUseCase: MemoryFormUseCase
) : ViewModel() {

    var title by mutableStateOf("")
        private set
    var selectedImage by mutableStateOf<Bitmap?>(null)
        private set
    var isSaving by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set

    private val _navigationEvent = MutableSharedFlow<NavigationEvent>()
    val navigationEvent: SharedFlow<NavigationEvent> = _navigationEvent.asSharedFlow()

    val navigationTitle: String = "New Memory"

    val isValid: Boolean
        get() = title.trim().isNotEmpty() && selectedImage != null

    fun onTitleChange(newTitle: String) {
        title = newTitle
    }

    fun onImageSelected(bitmap: Bitmap) {
        selectedImage = bitmap
    }

    fun save() {
        viewModelScope.launch {
            saveMemory()
        }
    }

    fun cancel() {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.Dismiss)
        }
    }

    fun clearError() {
        errorMessage = null
    }

    private suspend fun saveMemory() {
        val image = selectedImage ?: return

        isSaving = true
        errorMessage = null

        val stream = ByteArrayOutputStream()
        image.compress(Bitmap.CompressFormat.JPEG, 80, stream)
        val imageData = stream.toByteArray()

        when (val result = memoryFormUseCase.createMemory(album, title.trim(), imageData)) {
            is MemoryCreateResult.Success,
            is MemoryCreateResult.SuccessPendingSync -> {
                _navigationEvent.emit(NavigationEvent.Dismiss)
            }
            is MemoryCreateResult.Failure -> {
                errorMessage = mapError(result.error)
            }
        }

        isSaving = false
    }

    private fun mapError(error: com.example.memoriesapp.usecase.MemoryCreateError): String {
        return when (error) {
            com.example.memoriesapp.usecase.MemoryCreateError.NETWORK_ERROR ->
                "Network error. Please check your connection and try again."
            com.example.memoriesapp.usecase.MemoryCreateError.IMAGE_STORAGE_FAILED ->
                "Failed to save image. Please try again."
            com.example.memoriesapp.usecase.MemoryCreateError.DATABASE_ERROR ->
                "Failed to save memory. Please try again."
            else -> "An unexpected error occurred. Please try again."
        }
    }

    sealed class NavigationEvent {
        data object Dismiss : NavigationEvent()
    }
}
