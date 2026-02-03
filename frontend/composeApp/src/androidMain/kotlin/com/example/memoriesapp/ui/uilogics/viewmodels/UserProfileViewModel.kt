package com.example.memoriesapp.ui.uilogics.viewmodels

import android.graphics.Bitmap
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.usecase.UpdateProfileError
import com.example.memoriesapp.usecase.UpdateProfileResult
import com.example.memoriesapp.usecase.UserProfileUseCase
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.LocalDate
import java.io.ByteArrayOutputStream

class UserProfileViewModel(
    private val user: User,
    private val userProfileUseCase: UserProfileUseCase
) : ViewModel() {

    var name by mutableStateOf(user.name)
        private set
    var username by mutableStateOf(user.username)
        private set
    var birthday by mutableStateOf(user.birthday)
        private set
    var avatarUrl by mutableStateOf(user.displayAvatar)
        private set
    var selectedImage by mutableStateOf<Bitmap?>(null)
        private set
    var isSaving by mutableStateOf(false)
        private set
    var alertState by mutableStateOf<AlertState?>(null)
        private set

    private val _navigationEvent = MutableSharedFlow<NavigationEvent>()
    val navigationEvent: SharedFlow<NavigationEvent> = _navigationEvent.asSharedFlow()

    val isValid: Boolean
        get() = name.trim().isNotEmpty()

    fun onNameChange(newName: String) {
        name = newName
    }

    fun onBirthdayChange(newBirthday: LocalDate?) {
        birthday = newBirthday
    }

    fun onImageSelected(bitmap: Bitmap) {
        selectedImage = bitmap
    }

    fun save() {
        viewModelScope.launch {
            saveProfile()
        }
    }

    fun showLogoutConfirmation() {
        alertState = AlertState.LogoutConfirmation
    }

    fun confirmLogout() {
        viewModelScope.launch {
            userProfileUseCase.logout()
            _navigationEvent.emit(NavigationEvent.Logout)
        }
    }

    fun dismissAlert() {
        alertState = null
    }

    private suspend fun saveProfile() {
        isSaving = true

        val avatarData: ByteArray? = selectedImage?.let { bitmap ->
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream)
            stream.toByteArray()
        }

        when (val result = userProfileUseCase.updateProfile(name.trim(), birthday, avatarData)) {
            is UpdateProfileResult.Success -> {
                name = result.user.name
                birthday = result.user.birthday
                avatarUrl = result.user.displayAvatar
                selectedImage = null
                alertState = AlertState.SaveSuccess("Your profile has been updated.", result.user)
            }
            is UpdateProfileResult.SuccessPendingSync -> {
                name = result.user.name
                birthday = result.user.birthday
                avatarUrl = result.user.displayAvatar
                selectedImage = null
                alertState = AlertState.SaveSuccess("Your profile has been saved locally and will sync when online.", result.user)
            }
            is UpdateProfileResult.Failure -> {
                alertState = AlertState.SaveError(mapError(result.error))
            }
        }

        isSaving = false
    }

    private fun mapError(error: UpdateProfileError): String {
        return when (error) {
            UpdateProfileError.NETWORK_ERROR ->
                "Network error. Please check your connection and try again."
            UpdateProfileError.SERVER_ERROR ->
                "Server error. Please try again later."
            UpdateProfileError.IMAGE_STORAGE_FAILED ->
                "Failed to save the image locally. Please try again."
            UpdateProfileError.DATABASE_ERROR ->
                "Failed to save to local database. Please try again."
            UpdateProfileError.UNKNOWN ->
                "An unexpected error occurred. Please try again."
        }
    }

    sealed class AlertState {
        data object LogoutConfirmation : AlertState()
        data class SaveSuccess(val message: String, val updatedUser: User) : AlertState()
        data class SaveError(val message: String) : AlertState()
    }

    sealed class NavigationEvent {
        data object Logout : NavigationEvent()
    }

    fun getUpdatedUser(): User {
        return User(
            id = user.id,
            name = name,
            username = username,
            birthday = birthday,
            avatarUrl = avatarUrl,
            avatarLocalPath = user.avatarLocalPath,
            syncStatus = user.syncStatus
        )
    }
}
