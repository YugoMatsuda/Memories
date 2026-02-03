package com.example.memoriesapp.ui.uilogics.viewmodels

import com.example.memoriesapp.domain.AuthSession
import com.example.memoriesapp.usecase.LoginError
import com.example.memoriesapp.usecase.LoginResult
import com.example.memoriesapp.usecase.LoginUseCase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

@OptIn(ExperimentalCoroutinesApi::class)
class LoginViewModelTest {

    private val testDispatcher = UnconfinedTestDispatcher()

    @BeforeTest
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
    }

    @AfterTest
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state is Idle`() {
        val mockUseCase = MockLoginUseCase()
        val viewModel = LoginViewModel(mockUseCase)

        assertIs<LoginViewModel.LoginState.Idle>(viewModel.loginState)
        assertEquals("", viewModel.username)
        assertEquals("", viewModel.password)
    }

    @Test
    fun `onUsernameChange updates username`() {
        val mockUseCase = MockLoginUseCase()
        val viewModel = LoginViewModel(mockUseCase)

        viewModel.onUsernameChange("testuser")

        assertEquals("testuser", viewModel.username)
    }

    @Test
    fun `onPasswordChange updates password`() {
        val mockUseCase = MockLoginUseCase()
        val viewModel = LoginViewModel(mockUseCase)

        viewModel.onPasswordChange("password123")

        assertEquals("password123", viewModel.password)
    }

    @Test
    fun `login passes credentials to useCase`() = runTest {
        val mockUseCase = MockLoginUseCase()
        val session = AuthSession(token = "test-token", userId = 1)
        mockUseCase.loginResult = LoginResult.Success(session)

        val viewModel = LoginViewModel(mockUseCase)
        viewModel.onUsernameChange("myuser")
        viewModel.onPasswordChange("mypass")

        viewModel.login()
        advanceUntilIdle()

        assertEquals("myuser", mockUseCase.capturedUsername)
        assertEquals("mypass", mockUseCase.capturedPassword)
    }

    @Test
    fun `login invalidCredentials sets error state`() = runTest {
        val mockUseCase = MockLoginUseCase()
        mockUseCase.loginResult = LoginResult.Failure(LoginError.INVALID_CREDENTIALS)

        val viewModel = LoginViewModel(mockUseCase)

        viewModel.login()
        advanceUntilIdle()

        assertIs<LoginViewModel.LoginState.Error>(viewModel.loginState)
        val errorState = viewModel.loginState as LoginViewModel.LoginState.Error
        assertEquals("Invalid username or password", errorState.message)
    }

    @Test
    fun `login networkError sets error state`() = runTest {
        val mockUseCase = MockLoginUseCase()
        mockUseCase.loginResult = LoginResult.Failure(LoginError.NETWORK_ERROR)

        val viewModel = LoginViewModel(mockUseCase)

        viewModel.login()
        advanceUntilIdle()

        assertIs<LoginViewModel.LoginState.Error>(viewModel.loginState)
        val errorState = viewModel.loginState as LoginViewModel.LoginState.Error
        assertEquals("Network error", errorState.message)
    }

    @Test
    fun `login serverError sets error state`() = runTest {
        val mockUseCase = MockLoginUseCase()
        mockUseCase.loginResult = LoginResult.Failure(LoginError.SERVER_ERROR)

        val viewModel = LoginViewModel(mockUseCase)

        viewModel.login()
        advanceUntilIdle()

        assertIs<LoginViewModel.LoginState.Error>(viewModel.loginState)
        val errorState = viewModel.loginState as LoginViewModel.LoginState.Error
        assertEquals("Server error", errorState.message)
    }

    @Test
    fun `loginState isLoading returns correct value`() {
        assertEquals(false, LoginViewModel.LoginState.Idle.isLoading)
        assertEquals(true, LoginViewModel.LoginState.Loading.isLoading)
        assertEquals(false, LoginViewModel.LoginState.Error("test").isLoading)
    }
}

// Mock

private class MockLoginUseCase : LoginUseCase {
    var loginResult: LoginResult = LoginResult.Success(AuthSession(token = "default", userId = 1))
    var capturedUsername: String? = null
    var capturedPassword: String? = null

    override suspend fun login(username: String, password: String): LoginResult {
        capturedUsername = username
        capturedPassword = password
        return loginResult
    }
}
