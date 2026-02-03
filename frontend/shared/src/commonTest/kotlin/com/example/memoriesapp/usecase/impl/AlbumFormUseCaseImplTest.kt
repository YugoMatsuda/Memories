package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.AlbumResponse
import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.gateway.mock.MockAlbumGateway
import com.example.memoriesapp.repository.mock.MockAlbumRepository
import com.example.memoriesapp.repository.mock.MockImageStorageRepository
import com.example.memoriesapp.repository.mock.MockReachabilityRepository
import com.example.memoriesapp.usecase.AlbumCreateError
import com.example.memoriesapp.usecase.AlbumCreateResult
import com.example.memoriesapp.usecase.AlbumUpdateError
import com.example.memoriesapp.usecase.AlbumUpdateResult
import com.example.memoriesapp.usecase.mock.MockSyncQueueService
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull

class AlbumFormUseCaseImplTest {

    private val mockAlbumRepository = MockAlbumRepository()
    private val mockAlbumGateway = MockAlbumGateway()
    private val mockSyncQueueService = MockSyncQueueService()
    private val mockReachabilityRepository = MockReachabilityRepository()
    private val mockImageStorageRepository = MockImageStorageRepository()

    private val useCase = AlbumFormUseCaseImpl(
        albumRepository = mockAlbumRepository,
        albumGateway = mockAlbumGateway,
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

    private fun createAlbumResponse(id: Int, title: String) = AlbumResponse(
        id = id,
        title = title,
        coverImageUrl = "/uploads/cover_$id.jpg",
        createdAt = "2024-01-01T00:00:00Z"
    )

    // createAlbum() tests - Online

    @Test
    fun createAlbum_online_success_returnsCreatedAlbum() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumGateway.setAlbumResponse(createAlbumResponse(10, "New Album"))

        val result = useCase.createAlbum(title = "New Album", coverImageData = null)

        assertIs<AlbumCreateResult.Success>(result)
        assertEquals("New Album", result.album.title)
        assertEquals(10, result.album.serverId)
    }

    @Test
    fun createAlbum_online_withCoverImage_uploadsImage() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumGateway.setAlbumResponse(createAlbumResponse(10, "Album with Cover"))
        val coverData = byteArrayOf(1, 2, 3, 4, 5)

        val result = useCase.createAlbum(title = "Album with Cover", coverImageData = coverData)

        assertIs<AlbumCreateResult.Success>(result)
    }

    @Test
    fun createAlbum_online_apiError_returnsPendingSync() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumGateway.setError(ApiError.ServerError)

        val result = useCase.createAlbum(title = "Failed Album", coverImageData = null)

        assertIs<AlbumCreateResult.SuccessPendingSync>(result)
        assertEquals("Failed Album", result.album.title)
    }

    @Test
    fun createAlbum_online_savesToLocalDb() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumGateway.setAlbumResponse(createAlbumResponse(10, "New Album"))

        useCase.createAlbum(title = "New Album", coverImageData = null)

        val albums = mockAlbumRepository.getAlbums()
        assertEquals(1, albums.size)
    }

    // createAlbum() tests - Offline

    @Test
    fun createAlbum_offline_returnsPendingSync() = runTest {
        mockReachabilityRepository.setConnected(false)

        val result = useCase.createAlbum(title = "Offline Album", coverImageData = null)

        assertIs<AlbumCreateResult.SuccessPendingSync>(result)
        assertEquals("Offline Album", result.album.title)
        assertEquals(SyncStatus.PENDING_CREATE, result.album.syncStatus)
    }

    @Test
    fun createAlbum_offline_enqueuesSync() = runTest {
        mockReachabilityRepository.setConnected(false)

        useCase.createAlbum(title = "Offline Album", coverImageData = null)

        assertEquals(1, mockSyncQueueService.getEnqueuedOperations().size)
    }

    // createAlbum() error tests

    @Test
    fun createAlbum_imageStorageFails_returnsImageStorageFailedError() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockImageStorageRepository.setShouldThrowOnSave(true)

        val result = useCase.createAlbum(title = "Test", coverImageData = byteArrayOf(1, 2, 3))

        assertIs<AlbumCreateResult.Failure>(result)
        assertEquals(AlbumCreateError.IMAGE_STORAGE_FAILED, result.error)
    }

    // updateAlbum() tests - Online

    @Test
    fun updateAlbum_online_success_returnsUpdatedAlbum() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 5)
        mockAlbumGateway.setAlbumResponse(createAlbumResponse(5, "Updated Title"))

        val result = useCase.updateAlbum(album = album, title = "Updated Title", coverImageData = null)

        assertIs<AlbumUpdateResult.Success>(result)
        assertEquals("Updated Title", result.album.title)
    }

    @Test
    fun updateAlbum_online_apiError_returnsPendingSync() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 5)
        mockAlbumGateway.setError(ApiError.ServerError)

        val result = useCase.updateAlbum(album = album, title = "Updated Title", coverImageData = null)

        assertIs<AlbumUpdateResult.SuccessPendingSync>(result)
    }

    // updateAlbum() tests - Offline

    @Test
    fun updateAlbum_offline_returnsPendingSync() = runTest {
        mockReachabilityRepository.setConnected(false)
        val album = createAlbum(serverId = 5)

        val result = useCase.updateAlbum(album = album, title = "Offline Update", coverImageData = null)

        assertIs<AlbumUpdateResult.SuccessPendingSync>(result)
        assertEquals("Offline Update", result.album.title)
        assertEquals(SyncStatus.PENDING_UPDATE, result.album.syncStatus)
    }

    // updateAlbum() tests - Unsynced album

    @Test
    fun updateAlbum_unsyncedAlbum_returnsPendingSync() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = null)

        val result = useCase.updateAlbum(album = album, title = "Update Unsynced", coverImageData = null)

        assertIs<AlbumUpdateResult.SuccessPendingSync>(result)
    }

    // updateAlbum() error tests

    @Test
    fun updateAlbum_imageStorageFails_returnsImageStorageFailedError() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 5)
        mockImageStorageRepository.setShouldThrowOnSave(true)

        val result = useCase.updateAlbum(album = album, title = "Test", coverImageData = byteArrayOf(1, 2, 3))

        assertIs<AlbumUpdateResult.Failure>(result)
        assertEquals(AlbumUpdateError.IMAGE_STORAGE_FAILED, result.error)
    }
}
