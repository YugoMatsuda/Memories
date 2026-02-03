package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.AlbumResponse
import com.example.memoriesapp.api.response.MemoryResponse
import com.example.memoriesapp.api.response.PaginatedMemoriesResponse
import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.domain.Memory
import com.example.memoriesapp.gateway.mock.MockAlbumGateway
import com.example.memoriesapp.gateway.mock.MockMemoryGateway
import com.example.memoriesapp.repository.mock.MockAlbumRepository
import com.example.memoriesapp.repository.mock.MockMemoryRepository
import com.example.memoriesapp.repository.mock.MockReachabilityRepository
import com.example.memoriesapp.usecase.MemoryDisplayError
import com.example.memoriesapp.usecase.MemoryDisplayResult
import com.example.memoriesapp.usecase.MemoryNextError
import com.example.memoriesapp.usecase.MemoryNextResult
import com.example.memoriesapp.usecase.ResolveAlbumError
import com.example.memoriesapp.usecase.ResolveAlbumResult
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

class AlbumDetailUseCaseImplTest {

    private val mockMemoryRepository = MockMemoryRepository()
    private val mockAlbumRepository = MockAlbumRepository()
    private val mockAlbumGateway = MockAlbumGateway()
    private val mockMemoryGateway = MockMemoryGateway()
    private val mockReachabilityRepository = MockReachabilityRepository()

    private val useCase = AlbumDetailUseCaseImpl(
        memoryRepository = mockMemoryRepository,
        albumRepository = mockAlbumRepository,
        albumGateway = mockAlbumGateway,
        memoryGateway = mockMemoryGateway,
        reachabilityRepository = mockReachabilityRepository
    )

    private val albumLocalId = LocalId.generate()

    private fun createAlbum(serverId: Int? = 1) = Album(
        serverId = serverId,
        localId = albumLocalId,
        title = "Test Album",
        coverImageUrl = null,
        coverImageLocalPath = null,
        createdAt = Timestamp.now(),
        syncStatus = SyncStatus.SYNCED
    )

    private fun createMemoryResponse(id: Int, albumId: Int) = MemoryResponse(
        id = id,
        albumId = albumId,
        title = "Memory $id",
        imageLocalUri = "/uploads/memory_$id.jpg",
        createdAt = "2024-01-01T00:00:00Z"
    )

    private fun createMemory(serverId: Int, albumLocalId: LocalId) = Memory(
        serverId = serverId,
        localId = LocalId.generate(),
        albumId = 1,
        albumLocalId = albumLocalId,
        title = "Memory $serverId",
        imageUrl = "/uploads/memory_$serverId.jpg",
        imageLocalPath = null,
        createdAt = Timestamp.now(),
        syncStatus = SyncStatus.SYNCED
    )

    // display() tests - Synced album

    @Test
    fun display_online_syncedAlbum_returnsMemoriesFromApi() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 1)
        mockMemoryGateway.setPaginatedResponse(
            PaginatedMemoriesResponse(
                items = listOf(
                    createMemoryResponse(1, 1),
                    createMemoryResponse(2, 1)
                ),
                page = 1,
                pageSize = 5,
                total = 2
            )
        )

        val result = useCase.display(album)

        assertIs<MemoryDisplayResult.Success>(result)
        assertEquals(2, result.pageInfo.memories.size)
        assertEquals(false, result.pageInfo.hasMore)
    }

    @Test
    fun display_online_syncedAlbum_hasMore_whenTotalExceedsPageSize() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 1)
        mockMemoryGateway.setPaginatedResponse(
            PaginatedMemoriesResponse(
                items = listOf(createMemoryResponse(1, 1)),
                page = 1,
                pageSize = 5,
                total = 10
            )
        )

        val result = useCase.display(album)

        assertIs<MemoryDisplayResult.Success>(result)
        assertEquals(true, result.pageInfo.hasMore)
    }

    @Test
    fun display_online_apiError_fallsBackToCache() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 1)
        mockMemoryRepository.setMemories(listOf(createMemory(1, albumLocalId)))
        mockMemoryGateway.setError(ApiError.ServerError)

        val result = useCase.display(album)

        assertIs<MemoryDisplayResult.Success>(result)
        assertEquals(1, result.pageInfo.memories.size)
    }

    @Test
    fun display_online_apiError_emptyCache_returnsFailure() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 1)
        mockMemoryGateway.setError(ApiError.ServerError)

        val result = useCase.display(album)

        assertIs<MemoryDisplayResult.Failure>(result)
        assertEquals(MemoryDisplayError.UNKNOWN, result.error)
    }

    // display() tests - Unsynced album

    @Test
    fun display_unsyncedAlbum_returnsLocalMemoriesOnly() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = null)
        mockMemoryRepository.setMemories(listOf(createMemory(1, albumLocalId)))

        val result = useCase.display(album)

        assertIs<MemoryDisplayResult.Success>(result)
        assertEquals(1, result.pageInfo.memories.size)
        assertEquals(false, result.pageInfo.hasMore)
    }

    // display() tests - Offline

    @Test
    fun display_offline_returnsMemoriesFromCache() = runTest {
        mockReachabilityRepository.setConnected(false)
        val album = createAlbum(serverId = 1)
        mockMemoryRepository.setMemories(listOf(createMemory(1, albumLocalId)))

        val result = useCase.display(album)

        assertIs<MemoryDisplayResult.Success>(result)
        assertEquals(1, result.pageInfo.memories.size)
    }

    @Test
    fun display_offline_emptyCache_returnsEmptyList() = runTest {
        mockReachabilityRepository.setConnected(false)
        val album = createAlbum(serverId = 1)

        val result = useCase.display(album)

        assertIs<MemoryDisplayResult.Success>(result)
        assertEquals(0, result.pageInfo.memories.size)
    }

    // next() tests

    @Test
    fun next_online_success_returnsNextPageMemories() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = 1)
        mockMemoryGateway.setPaginatedResponse(
            PaginatedMemoriesResponse(
                items = listOf(createMemoryResponse(6, 1)),
                page = 2,
                pageSize = 5,
                total = 15  // 2*5=10 < 15, so hasMore = true
            )
        )

        val result = useCase.next(album, page = 2)

        assertIs<MemoryNextResult.Success>(result)
        assertEquals(true, result.pageInfo.hasMore)
    }

    @Test
    fun next_offline_returnsOfflineError() = runTest {
        mockReachabilityRepository.setConnected(false)
        val album = createAlbum(serverId = 1)

        val result = useCase.next(album, page = 2)

        assertIs<MemoryNextResult.Failure>(result)
        assertEquals(MemoryNextError.OFFLINE, result.error)
    }

    @Test
    fun next_unsyncedAlbum_returnsOfflineError() = runTest {
        mockReachabilityRepository.setConnected(true)
        val album = createAlbum(serverId = null)

        val result = useCase.next(album, page = 2)

        assertIs<MemoryNextResult.Failure>(result)
        assertEquals(MemoryNextError.OFFLINE, result.error)
    }

    // resolveAlbum() tests

    @Test
    fun resolveAlbum_online_success_returnsAlbum() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumGateway.setAlbumResponse(
            AlbumResponse(
                id = 5,
                title = "Resolved Album",
                createdAt = "2024-01-01T00:00:00Z"
            )
        )

        val result = useCase.resolveAlbum(serverId = 5)

        assertIs<ResolveAlbumResult.Success>(result)
        assertEquals("Resolved Album", result.album.title)
    }

    @Test
    fun resolveAlbum_online_notFound_returnsNotFoundError() = runTest {
        mockReachabilityRepository.setConnected(true)
        mockAlbumGateway.setError(ApiError.NotFound)

        val result = useCase.resolveAlbum(serverId = 999)

        assertIs<ResolveAlbumResult.Failure>(result)
        assertEquals(ResolveAlbumError.NOT_FOUND, result.error)
    }

    @Test
    fun resolveAlbum_offline_withCache_returnsAlbumFromCache() = runTest {
        mockReachabilityRepository.setConnected(false)
        mockAlbumRepository.setAlbums(listOf(createAlbum(serverId = 5)))

        val result = useCase.resolveAlbum(serverId = 5)

        assertIs<ResolveAlbumResult.Success>(result)
    }

    @Test
    fun resolveAlbum_offline_noCache_returnsOfflineUnavailableError() = runTest {
        mockReachabilityRepository.setConnected(false)

        val result = useCase.resolveAlbum(serverId = 5)

        assertIs<ResolveAlbumResult.Failure>(result)
        assertEquals(ResolveAlbumError.OFFLINE_UNAVAILABLE, result.error)
    }
}
