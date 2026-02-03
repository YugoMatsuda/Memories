package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.AlbumResponse
import com.example.memoriesapp.api.response.PaginatedAlbumsResponse
import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.gateway.mock.MockAlbumGateway
import com.example.memoriesapp.repository.mock.MockAlbumRepository
import com.example.memoriesapp.repository.mock.MockReachabilityRepository
import com.example.memoriesapp.repository.mock.MockSyncQueueRepository
import com.example.memoriesapp.repository.mock.MockUserRepository
import com.example.memoriesapp.usecase.AlbumDisplayError
import com.example.memoriesapp.usecase.AlbumDisplayResult
import com.example.memoriesapp.usecase.AlbumNextError
import com.example.memoriesapp.usecase.AlbumNextResult
import com.example.memoriesapp.usecase.mock.MockSyncQueueService
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

class AlbumListUseCaseImplTest {

    private val mockUserRepository = MockUserRepository()
    private val mockAlbumRepository = MockAlbumRepository()
    private val mockAlbumGateway = MockAlbumGateway()
    private val mockReachabilityRepository = MockReachabilityRepository()
    private val mockSyncQueueService = MockSyncQueueService()
    private val mockSyncQueueRepository = MockSyncQueueRepository()

    private val useCase = AlbumListUseCaseImpl(
        userRepository = mockUserRepository,
        albumRepository = mockAlbumRepository,
        albumGateway = mockAlbumGateway,
        reachabilityRepository = mockReachabilityRepository,
        syncQueueService = mockSyncQueueService,
        syncQueueRepository = mockSyncQueueRepository
    )

    private fun createAlbumResponse(id: Int, title: String) = AlbumResponse(
        id = id,
        title = title,
        coverImageUrl = "/uploads/cover_$id.jpg",
        createdAt = "2024-01-01T00:00:00Z"
    )

    private fun createAlbum(serverId: Int, title: String) = Album(
        serverId = serverId,
        localId = LocalId.generate(),
        title = title,
        coverImageUrl = "/uploads/cover_$serverId.jpg",
        coverImageLocalPath = null,
        createdAt = Timestamp.now(),
        syncStatus = SyncStatus.SYNCED
    )

    // display() tests - Online

    @Test
    fun display_online_success_returnsAlbumsFromApi() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumGateway.setPaginatedResponse(
            PaginatedAlbumsResponse(
                items = listOf(
                    createAlbumResponse(1, "Album 1"),
                    createAlbumResponse(2, "Album 2")
                ),
                page = 1,
                pageSize = 5,
                total = 2
            )
        )

        val result = useCase.display()

        assertIs<AlbumDisplayResult.Success>(result)
        assertEquals(2, result.pageInfo.albums.size)
        assertEquals(false, result.pageInfo.hasMore)
    }

    @Test
    fun display_online_success_syncsAlbumsToRepository() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumGateway.setPaginatedResponse(
            PaginatedAlbumsResponse(
                items = listOf(createAlbumResponse(1, "Album 1")),
                page = 1,
                pageSize = 5,
                total = 1
            )
        )

        useCase.display()

        val cachedAlbums = mockAlbumRepository.getAlbums()
        assertEquals(1, cachedAlbums.size)
        assertEquals("Album 1", cachedAlbums[0].title)
    }

    @Test
    fun display_online_hasMore_whenTotalExceedsPageSize() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumGateway.setPaginatedResponse(
            PaginatedAlbumsResponse(
                items = listOf(
                    createAlbumResponse(1, "Album 1"),
                    createAlbumResponse(2, "Album 2")
                ),
                page = 1,
                pageSize = 5,
                total = 10
            )
        )

        val result = useCase.display()

        assertIs<AlbumDisplayResult.Success>(result)
        assertEquals(true, result.pageInfo.hasMore)
    }

    @Test
    fun display_online_apiError_fallsBackToCache() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumRepository.setAlbums(listOf(createAlbum(1, "Cached Album")))
        mockAlbumGateway.setError(ApiError.ServerError)

        val result = useCase.display()

        assertIs<AlbumDisplayResult.Success>(result)
        assertEquals(1, result.pageInfo.albums.size)
        assertEquals("Cached Album", result.pageInfo.albums[0].title)
        assertEquals(false, result.pageInfo.hasMore)
    }

    @Test
    fun display_online_apiError_emptyCache_returnsFailure() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumRepository.setAlbums(emptyList())
        mockAlbumGateway.setError(ApiError.ServerError)

        val result = useCase.display()

        assertIs<AlbumDisplayResult.Failure>(result)
        assertEquals(AlbumDisplayError.UNKNOWN, result.error)
    }

    // display() tests - Offline

    @Test
    fun display_offline_returnsAlbumsFromCache() = runTest {
        mockReachabilityRepository.setConnected(false)
        mockAlbumRepository.setAlbums(
            listOf(
                createAlbum(1, "Cached 1"),
                createAlbum(2, "Cached 2")
            )
        )

        val result = useCase.display()

        assertIs<AlbumDisplayResult.Success>(result)
        assertEquals(2, result.pageInfo.albums.size)
        assertEquals(false, result.pageInfo.hasMore)
    }

    @Test
    fun display_offline_emptyCache_returnsOfflineError() = runTest {
        mockReachabilityRepository.setConnected(false)
        mockAlbumRepository.setAlbums(emptyList())

        val result = useCase.display()

        assertIs<AlbumDisplayResult.Failure>(result)
        assertEquals(AlbumDisplayError.OFFLINE, result.error)
    }

    // next() tests

    @Test
    fun next_online_success_returnsNextPageAlbums() = runTest {
        mockReachabilityRepository.setConnected(true)
        // Simulate first page already loaded
        mockAlbumRepository.setAlbums(
            (1..5).map { createAlbum(it, "Album $it") }
        )
        mockAlbumGateway.setPaginatedResponse(
            PaginatedAlbumsResponse(
                items = (6..10).map { createAlbumResponse(it, "Album $it") },
                page = 2,
                pageSize = 5,
                total = 15
            )
        )

        val result = useCase.next(page = 2)

        assertIs<AlbumNextResult.Success>(result)
        assertEquals(true, result.pageInfo.hasMore)
    }

    @Test
    fun next_offline_returnsOfflineError() = runTest {
        mockReachabilityRepository.setConnected(false)

        val result = useCase.next(page = 2)

        assertIs<AlbumNextResult.Failure>(result)
        assertEquals(AlbumNextError.OFFLINE, result.error)
    }

    @Test
    fun next_apiError_returnsUnknownError() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumGateway.setError(ApiError.ServerError)

        val result = useCase.next(page = 2)

        assertIs<AlbumNextResult.Failure>(result)
        assertEquals(AlbumNextError.UNKNOWN, result.error)
    }
}
