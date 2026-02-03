package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.MemoryResponse
import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.gateway.mock.MockMemoryGateway
import com.example.memoriesapp.repository.mock.MockImageStorageRepository
import com.example.memoriesapp.repository.mock.MockMemoryRepository
import com.example.memoriesapp.repository.mock.MockReachabilityRepository
import com.example.memoriesapp.usecase.MemoryCreateError
import com.example.memoriesapp.usecase.MemoryCreateResult
import com.example.memoriesapp.usecase.mock.MockSyncQueueService
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

class MemoryFormUseCaseImplTest {

    private val mockMemoryRepository = MockMemoryRepository()
    private val mockMemoryGateway = MockMemoryGateway()
    private val mockSyncQueueService = MockSyncQueueService()
    private val mockReachabilityRepository = MockReachabilityRepository()
    private val mockImageStorageRepository = MockImageStorageRepository()

    private val useCase = MemoryFormUseCaseImpl(
        memoryRepository = mockMemoryRepository,
        memoryGateway = mockMemoryGateway,
        syncQueueService = mockSyncQueueService,
        reachabilityRepository = mockReachabilityRepository,
        imageStorageRepository = mockImageStorageRepository
    )

    private fun createAlbum(serverId: Int? = 1) = Album(
        serverId = serverId,
        localId = LocalId.generate(),
        title = "Test Album",
        coverImageUrl = null,
        coverImageLocalPath = null,
        createdAt = Timestamp.now(),
        syncStatus = SyncStatus.SYNCED
    )

    private fun createMemoryResponse(id: Int, albumId: Int) = MemoryResponse(
        id = id,
        albumId = albumId,
        title = "New Memory",
        imageLocalUri = "/uploads/memory_$id.jpg",
        createdAt = "2024-01-01T00:00:00Z"
    )

    private val imageData = byteArrayOf(1, 2, 3, 4, 5)

    // Online tests - Synced album

    @Test
    fun createMemory_online_syncedAlbum_success_returnsCreatedMemory() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 5)
        mockMemoryGateway.setMemoryResponse(createMemoryResponse(10, 5))

        val result = useCase.createMemory(album = album, title = "New Memory", imageData = imageData)

        assertIs<MemoryCreateResult.Success>(result)
        assertEquals(10, result.memory.serverId)
    }

    @Test
    fun createMemory_online_syncedAlbum_apiError_returnsPendingSync() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 5)
        mockMemoryGateway.setError(ApiError.ServerError)

        val result = useCase.createMemory(album = album, title = "New Memory", imageData = imageData)

        assertIs<MemoryCreateResult.SuccessPendingSync>(result)
        assertEquals("New Memory", result.memory.title)
    }

    @Test
    fun createMemory_online_syncedAlbum_savesToLocalDb() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 5)
        mockMemoryGateway.setMemoryResponse(createMemoryResponse(10, 5))

        useCase.createMemory(album = album, title = "New Memory", imageData = imageData)

        val memories = mockMemoryRepository.getMemories()
        assertEquals(1, memories.size)
    }

    // Online tests - Unsynced album

    @Test
    fun createMemory_online_unsyncedAlbum_returnsPendingSync() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = null)

        val result = useCase.createMemory(album = album, title = "New Memory", imageData = imageData)

        assertIs<MemoryCreateResult.SuccessPendingSync>(result)
        assertEquals(SyncStatus.PENDING_CREATE, result.memory.syncStatus)
    }

    @Test
    fun createMemory_online_unsyncedAlbum_enqueuesSync() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = null)

        useCase.createMemory(album = album, title = "New Memory", imageData = imageData)

        assertEquals(1, mockSyncQueueService.getEnqueuedOperations().size)
    }

    // Offline tests

    @Test
    fun createMemory_offline_returnsPendingSync() = runTest {
        mockReachabilityRepository.setConnected(false)
        val album = createAlbum(serverId = 5)

        val result = useCase.createMemory(album = album, title = "Offline Memory", imageData = imageData)

        assertIs<MemoryCreateResult.SuccessPendingSync>(result)
        assertEquals("Offline Memory", result.memory.title)
        assertEquals(SyncStatus.PENDING_CREATE, result.memory.syncStatus)
    }

    @Test
    fun createMemory_offline_enqueuesSync() = runTest {
        mockReachabilityRepository.setConnected(false)
        val album = createAlbum(serverId = 5)

        useCase.createMemory(album = album, title = "Offline Memory", imageData = imageData)

        assertEquals(1, mockSyncQueueService.getEnqueuedOperations().size)
    }

    @Test
    fun createMemory_offline_savesImageLocally() = runTest {
        mockReachabilityRepository.setConnected(false)
        val album = createAlbum(serverId = 5)

        useCase.createMemory(album = album, title = "Offline Memory", imageData = imageData)

        val storedData = mockImageStorageRepository.getStoredData()
        assertEquals(1, storedData.size)
    }

    // Error tests

    @Test
    fun createMemory_imageStorageFails_returnsImageStorageFailedError() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 5)
        mockImageStorageRepository.setShouldThrowOnSave(true)

        val result = useCase.createMemory(album = album, title = "Test", imageData = imageData)

        assertIs<MemoryCreateResult.Failure>(result)
        assertEquals(MemoryCreateError.IMAGE_STORAGE_FAILED, result.error)
    }
}
