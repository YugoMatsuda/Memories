package com.example.memoriesapp.ui.uilogics.viewmodels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.usecase.LaunchAppError
import com.example.memoriesapp.usecase.LaunchAppResult
import com.example.memoriesapp.usecase.SplashUseCase
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch

/**
 * ViewModel for splash screen.
 */
class SplashViewModel(
    private val splashUseCase: SplashUseCase
) : ViewModel() {

    var state by mutableStateOf<State>(State.Initial)
        private set

    private val _navigationEvent = MutableSharedFlow<NavigationEvent>()
    val navigationEvent: SharedFlow<NavigationEvent> = _navigationEvent.asSharedFlow()

    fun launchApp() {
        viewModelScope.launch {
            state = State.Loading("Loading user data...")
            when (val result = splashUseCase.launchApp()) {
                is LaunchAppResult.Success -> {
                    _navigationEvent.emit(NavigationEvent.LaunchSuccess(result.user))
                }
                is LaunchAppResult.Failure -> {
                    handleError(result.error)
                }
            }
        }
    }

    private fun handleError(error: LaunchAppError) {
        state = when (error) {
            LaunchAppError.SESSION_EXPIRED -> State.Error(
                ErrorItem(
                    message = "Session has expired",
                    buttonTitle = "Go to Login",
                    action = {
                        splashUseCase.clearSession()
                        viewModelScope.launch {
                            _navigationEvent.emit(NavigationEvent.SessionExpired)
                        }
                    }
                )
            )
            LaunchAppError.NETWORK_ERROR -> State.Error(
                ErrorItem(
                    message = "Network error occurred",
                    buttonTitle = "Retry",
                    action = { launchApp() }
                )
            )
            LaunchAppError.OFFLINE_NO_CACHE -> State.Error(
                ErrorItem(
                    message = "You're offline with no cached data",
                    buttonTitle = "Retry",
                    action = { launchApp() }
                )
            )
            LaunchAppError.SERVER_ERROR -> State.Error(
                ErrorItem(
                    message = "Server error occurred",
                    buttonTitle = "Retry",
                    action = { launchApp() }
                )
            )
            LaunchAppError.UNKNOWN -> State.Error(
                ErrorItem(
                    message = "Unknown error occurred",
                    buttonTitle = "Retry",
                    action = { launchApp() }
                )
            )
        }
    }

    sealed class State {
        data object Initial : State()
        data class Loading(val message: String) : State()
        data class Error(val item: ErrorItem) : State()
    }

    data class ErrorItem(
        val message: String,
        val buttonTitle: String,
        val action: () -> Unit
    )

    sealed class NavigationEvent {
        data class LaunchSuccess(val user: User) : NavigationEvent()
        data object SessionExpired : NavigationEvent()
    }
}
