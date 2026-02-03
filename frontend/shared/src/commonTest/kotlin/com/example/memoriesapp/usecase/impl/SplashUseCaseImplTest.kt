package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.UserResponse
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.gateway.mock.MockUserGateway
import com.example.memoriesapp.repository.mock.MockAuthSessionRepository
import com.example.memoriesapp.repository.mock.MockReachabilityRepository
import com.example.memoriesapp.repository.mock.MockSyncQueueRepository
import com.example.memoriesapp.repository.mock.MockUserRepository
import com.example.memoriesapp.usecase.LaunchAppError
import com.example.memoriesapp.usecase.LaunchAppResult
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull

class SplashUseCaseImplTest {

    private val mockUserGateway = MockUserGateway()
    private val mockUserRepository = MockUserRepository()
    private val mockAuthSessionRepository = MockAuthSessionRepository()
    private val mockReachabilityRepository = MockReachabilityRepository()
    private val mockSyncQueueRepository = MockSyncQueueRepository()

    private val useCase = SplashUseCaseImpl(
        userGateway = mockUserGateway,
        userRepository = mockUserRepository,
        authSessionRepository = mockAuthSessionRepository,
        reachabilityRepository = mockReachabilityRepository,
        syncQueueRepository = mockSyncQueueRepository
    )

    private fun createUserResponse() = UserResponse(
        id = 1,
        name = "Test User",
        username = "testuser",
        birthday = "1990-01-01",
        avatarUrl = "/uploads/avatar.jpg"
    )

    private fun createUser() = User(
        id = 1,
        name = "Cached User",
        username = "cached",
        birthday = null,
        avatarUrl = null,
        syncStatus = SyncStatus.SYNCED
    )

    // Online tests

    @Test
    fun launchApp_online_success_returnsUserFromApi() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockUserGateway.setResponse(createUserResponse())

        val result = useCase.launchApp()

        assertIs<LaunchAppResult.Success>(result)
        assertEquals("Test User", result.user.name)
        assertEquals("testuser", result.user.username)
    }

    @Test
    fun launchApp_online_apiError_fallsBackToCache() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockUserRepository.setUser(createUser())
        mockUserGateway.setError(ApiError.ServerError)

        val result = useCase.launchApp()

        assertIs<LaunchAppResult.Success>(result)
        assertEquals("Cached User", result.user.name)
    }

    @Test
    fun launchApp_online_sessionExpired_returnsSessionExpiredError() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockUserGateway.setError(ApiError.InvalidApiToken)

        val result = useCase.launchApp()

        assertIs<LaunchAppResult.Failure>(result)
        assertEquals(LaunchAppError.SESSION_EXPIRED, result.error)
    }

    @Test
    fun launchApp_online_networkError_returnsNetworkError() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockUserGateway.setError(ApiError.NetworkError(Exception("Connection failed")))

        val result = useCase.launchApp()

        assertIs<LaunchAppResult.Failure>(result)
        assertEquals(LaunchAppError.NETWORK_ERROR, result.error)
    }

    @Test
    fun launchApp_online_timeout_returnsNetworkError() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockUserGateway.setError(ApiError.Timeout)

        val result = useCase.launchApp()

        assertIs<LaunchAppResult.Failure>(result)
        assertEquals(LaunchAppError.NETWORK_ERROR, result.error)
    }

    @Test
    fun launchApp_online_serverError_returnsServerError() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockUserGateway.setError(ApiError.ServerError)

        val result = useCase.launchApp()

        assertIs<LaunchAppResult.Failure>(result)
        assertEquals(LaunchAppError.SERVER_ERROR, result.error)
    }

    // Offline tests

    @Test
    fun launchApp_offline_withCache_returnsUserFromCache() = runTest {
        mockReachabilityRepository.setConnected(false)
        mockUserRepository.setUser(createUser())

        val result = useCase.launchApp()

        assertIs<LaunchAppResult.Success>(result)
        assertEquals("Cached User", result.user.name)
    }

    @Test
    fun launchApp_offline_noCache_returnsOfflineNoCacheError() = runTest {
        mockReachabilityRepository.setConnected(false)
        // No user set in repository

        val result = useCase.launchApp()

        assertIs<LaunchAppResult.Failure>(result)
        assertEquals(LaunchAppError.OFFLINE_NO_CACHE, result.error)
    }

    // clearSession tests

    @Test
    fun clearSession_clearsAuthSession() = runTest {
        mockAuthSessionRepository.save(
            com.example.memoriesapp.domain.AuthSession(token = "test-token", userId = 1)
        )

        useCase.clearSession()

        assertNull(mockAuthSessionRepository.getSavedSession())
    }
}
