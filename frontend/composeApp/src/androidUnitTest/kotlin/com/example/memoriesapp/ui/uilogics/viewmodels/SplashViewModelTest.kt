package com.example.memoriesapp.ui.uilogics.viewmodels

import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.usecase.LaunchAppError
import com.example.memoriesapp.usecase.LaunchAppResult
import com.example.memoriesapp.usecase.SplashUseCase
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
class SplashViewModelTest {

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
    fun `initial state is Initial`() {
        val mockUseCase = MockSplashUseCase()
        val viewModel = SplashViewModel(mockUseCase)

        assertIs<SplashViewModel.State.Initial>(viewModel.state)
    }

    @Test
    fun `launchApp sessionExpired sets error state`() = runTest {
        val mockUseCase = MockSplashUseCase()
        mockUseCase.launchAppResult = LaunchAppResult.Failure(LaunchAppError.SESSION_EXPIRED)

        val viewModel = SplashViewModel(mockUseCase)

        viewModel.launchApp()
        advanceUntilIdle()

        assertIs<SplashViewModel.State.Error>(viewModel.state)
        val errorState = viewModel.state as SplashViewModel.State.Error
        assertEquals("Session has expired", errorState.item.message)
        assertEquals("Go to Login", errorState.item.buttonTitle)
    }

    @Test
    fun `launchApp networkError sets error state with retry`() = runTest {
        val mockUseCase = MockSplashUseCase()
        mockUseCase.launchAppResult = LaunchAppResult.Failure(LaunchAppError.NETWORK_ERROR)

        val viewModel = SplashViewModel(mockUseCase)

        viewModel.launchApp()
        advanceUntilIdle()

        assertIs<SplashViewModel.State.Error>(viewModel.state)
        val errorState = viewModel.state as SplashViewModel.State.Error
        assertEquals("Network error occurred", errorState.item.message)
        assertEquals("Retry", errorState.item.buttonTitle)
    }

    @Test
    fun `launchApp offlineNoCache sets error state`() = runTest {
        val mockUseCase = MockSplashUseCase()
        mockUseCase.launchAppResult = LaunchAppResult.Failure(LaunchAppError.OFFLINE_NO_CACHE)

        val viewModel = SplashViewModel(mockUseCase)

        viewModel.launchApp()
        advanceUntilIdle()

        assertIs<SplashViewModel.State.Error>(viewModel.state)
        val errorState = viewModel.state as SplashViewModel.State.Error
        assertEquals("You're offline with no cached data", errorState.item.message)
        assertEquals("Retry", errorState.item.buttonTitle)
    }

    @Test
    fun `launchApp serverError sets error state`() = runTest {
        val mockUseCase = MockSplashUseCase()
        mockUseCase.launchAppResult = LaunchAppResult.Failure(LaunchAppError.SERVER_ERROR)

        val viewModel = SplashViewModel(mockUseCase)

        viewModel.launchApp()
        advanceUntilIdle()

        assertIs<SplashViewModel.State.Error>(viewModel.state)
        val errorState = viewModel.state as SplashViewModel.State.Error
        assertEquals("Server error occurred", errorState.item.message)
        assertEquals("Retry", errorState.item.buttonTitle)
    }

    @Test
    fun `launchApp unknownError sets error state`() = runTest {
        val mockUseCase = MockSplashUseCase()
        mockUseCase.launchAppResult = LaunchAppResult.Failure(LaunchAppError.UNKNOWN)

        val viewModel = SplashViewModel(mockUseCase)

        viewModel.launchApp()
        advanceUntilIdle()

        assertIs<SplashViewModel.State.Error>(viewModel.state)
        val errorState = viewModel.state as SplashViewModel.State.Error
        assertEquals("Unknown error occurred", errorState.item.message)
        assertEquals("Retry", errorState.item.buttonTitle)
    }

    // Helper

    private fun createTestUser(
        id: Int = 1,
        name: String = "Test User",
        username: String = "testuser"
    ): User = User(
        id = id,
        name = name,
        username = username,
        birthday = null,
        avatarUrl = null,
        syncStatus = SyncStatus.SYNCED
    )
}

// Mock

private class MockSplashUseCase : SplashUseCase {
    var launchAppResult: LaunchAppResult = LaunchAppResult.Success(
        User(
            id = 1,
            name = "Default",
            username = "default",
            birthday = null,
            avatarUrl = null,
            syncStatus = SyncStatus.SYNCED
        )
    )
    var clearSessionCalled = false

    override suspend fun launchApp(): LaunchAppResult = launchAppResult

    override fun clearSession() {
        clearSessionCalled = true
    }
}
