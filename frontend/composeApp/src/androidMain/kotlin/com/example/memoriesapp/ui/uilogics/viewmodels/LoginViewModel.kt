package com.example.memoriesapp.ui.uilogics.viewmodels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.memoriesapp.domain.AuthSession
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.usecase.LoginError
import com.example.memoriesapp.usecase.LoginResult
import com.example.memoriesapp.usecase.LoginUseCase
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch

/**
 * ViewModel for login screen.
 */
class LoginViewModel(
    private val loginUseCase: LoginUseCase,
    val continueAsItem: ContinueAsItem? = null
) : ViewModel() {

    var username by mutableStateOf("")
        private set
    var password by mutableStateOf("")
        private set
    var loginState by mutableStateOf<LoginState>(LoginState.Idle)
        private set

    private val _navigationEvent = MutableSharedFlow<NavigationEvent>()
    val navigationEvent: SharedFlow<NavigationEvent> = _navigationEvent.asSharedFlow()

    fun onUsernameChange(value: String) {
        username = value
    }

    fun onPasswordChange(value: String) {
        password = value
    }

    fun login() {
        viewModelScope.launch {
            loginState = LoginState.Loading
            when (val result = loginUseCase.login(username, password)) {
                is LoginResult.Success -> {
                    loginState = LoginState.Idle
                    _navigationEvent.emit(NavigationEvent.LoginSuccess(result.session))
                }
                is LoginResult.Failure -> {
                    loginState = LoginState.Error(errorMessage(result.error))
                }
            }
        }
    }

    fun continueAsUser() {
        viewModelScope.launch {
            _navigationEvent.emit(NavigationEvent.ContinueAsUser)
        }
    }

    private fun errorMessage(error: LoginError): String {
        return when (error) {
            LoginError.INVALID_CREDENTIALS -> "Invalid username or password"
            LoginError.NETWORK_ERROR -> "Network error"
            LoginError.SERVER_ERROR -> "Server error"
            LoginError.UNKNOWN -> "Unknown error"
        }
    }

    data class ContinueAsItem(
        val userName: String,
        val avatarUrl: String?
    )

    sealed class LoginState {
        data object Idle : LoginState()
        data object Loading : LoginState()
        data class Error(val message: String) : LoginState()

        val isLoading: Boolean
            get() = this is Loading
    }

    sealed class NavigationEvent {
        data class LoginSuccess(val session: AuthSession) : NavigationEvent()
        data object ContinueAsUser : NavigationEvent()
    }
}
