package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.UserResponse
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.gateway.mock.MockUserGateway
import com.example.memoriesapp.repository.mock.MockAuthSessionRepository
import com.example.memoriesapp.repository.mock.MockImageStorageRepository
import com.example.memoriesapp.repository.mock.MockReachabilityRepository
import com.example.memoriesapp.repository.mock.MockUserRepository
import com.example.memoriesapp.usecase.UpdateProfileError
import com.example.memoriesapp.usecase.UpdateProfileResult
import com.example.memoriesapp.usecase.mock.MockSyncQueueService
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull

class UserProfileUseCaseImplTest {

    private val mockUserGateway = MockUserGateway()
    private val mockUserRepository = MockUserRepository()
    private val mockAuthSessionRepository = MockAuthSessionRepository()
    private val mockSyncQueueService = MockSyncQueueService()
    private val mockReachabilityRepository = MockReachabilityRepository()
    private val mockImageStorageRepository = MockImageStorageRepository()

    private val useCase = UserProfileUseCaseImpl(
        userGateway = mockUserGateway,
        userRepository = mockUserRepository,
        authSessionRepository = mockAuthSessionRepository,
        syncQueueService = mockSyncQueueService,
        reachabilityRepository = mockReachabilityRepository,
        imageStorageRepository = mockImageStorageRepository
    )

    private fun createUser() = User(
        id = 1,
        name = "Original Name",
        username = "testuser",
        birthday = LocalDate(1990, 1, 1),
        avatarUrl = "/uploads/avatar.jpg",
        syncStatus = SyncStatus.SYNCED
    )

    private fun createUserResponse(name: String = "Updated Name") = UserResponse(
        id = 1,
        name = name,
        username = "testuser",
        birthday = "1995-06-15",
        avatarUrl = "/uploads/new_avatar.jpg"
    )

    // Online tests

    @Test
    fun updateProfile_online_success_returnsUpdatedUser() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockUserRepository.setUser(createUser())
        mockUserGateway.setResponse(createUserResponse())

        val result = useCase.updateProfile(
            name = "Updated Name",
            birthday = LocalDate(1995, 6, 15),
            avatarData = null
        )

        assertIs<UpdateProfileResult.Success>(result)
        assertEquals("Updated Name", result.user.name)
    }

    @Test
    fun updateProfile_online_withAvatar_uploadsAvatar() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockUserRepository.setUser(createUser())
        mockUserGateway.setResponse(createUserResponse())
        val avatarData = byteArrayOf(1, 2, 3, 4, 5)

        val result = useCase.updateProfile(
            name = "Updated Name",
            birthday = null,
            avatarData = avatarData
        )

        assertIs<UpdateProfileResult.Success>(result)
    }

    @Test
    fun updateProfile_online_apiError_returnsPendingSync() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockUserRepository.setUser(createUser())
        mockUserGateway.setError(ApiError.ServerError)

        val result = useCase.updateProfile(
            name = "Updated Name",
            birthday = null,
            avatarData = null
        )

        assertIs<UpdateProfileResult.SuccessPendingSync>(result)
    }

    // Offline tests

    @Test
    fun updateProfile_offline_returnsPendingSync() = runTest {
        mockReachabilityRepository.setConnected(false)
        mockUserRepository.setUser(createUser())

        val result = useCase.updateProfile(
            name = "Offline Update",
            birthday = LocalDate(2000, 1, 1),
            avatarData = null
        )

        assertIs<UpdateProfileResult.SuccessPendingSync>(result)
        assertEquals("Offline Update", result.user.name)
        assertEquals(SyncStatus.PENDING_UPDATE, result.user.syncStatus)
    }

    @Test
    fun updateProfile_offline_enqueuesSync() = runTest {
        mockReachabilityRepository.setConnected(false)
        mockUserRepository.setUser(createUser())

        useCase.updateProfile(
            name = "Offline Update",
            birthday = null,
            avatarData = null
        )

        assertEquals(1, mockSyncQueueService.getEnqueuedOperations().size)
    }

    // Error tests

    @Test
    fun updateProfile_noCurrentUser_returnsUnknownError() = runTest {
        mockReachabilityRepository.setConnected(true)
        // No user set in repository

        val result = useCase.updateProfile(
            name = "Test",
            birthday = null,
            avatarData = null
        )

        assertIs<UpdateProfileResult.Failure>(result)
        assertEquals(UpdateProfileError.UNKNOWN, result.error)
    }

    @Test
    fun updateProfile_imageStorageFails_returnsImageStorageFailedError() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockUserRepository.setUser(createUser())
        mockImageStorageRepository.setShouldThrowOnSave(true)

        val result = useCase.updateProfile(
            name = "Test",
            birthday = null,
            avatarData = byteArrayOf(1, 2, 3)
        )

        assertIs<UpdateProfileResult.Failure>(result)
        assertEquals(UpdateProfileError.IMAGE_STORAGE_FAILED, result.error)
    }

    // logout tests

    @Test
    fun logout_clearsAuthSession() = runTest {
        mockAuthSessionRepository.save(
            com.example.memoriesapp.domain.AuthSession(token = "test-token", userId = 1)
        )

        useCase.logout()

        assertNull(mockAuthSessionRepository.getSavedSession())
    }
}
