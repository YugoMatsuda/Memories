package com.example.memoriesapp.gateway.impl

import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MemoryGatewayImplTest {

    private val mockApiClient = MockApiClient()
    private val gateway = MemoryGatewayImpl(mockApiClient)

    @Test
    fun getMemories_decodesPaginatedMemoriesResponse() = runTest {
        // Given - Backend returns PaginatedMemories schema
        val json = """{
            "items": [
                {
                    "id": 1,
                    "album_id": 5,
                    "title": "Beach Sunset",
                    "image_local_uri": "/uploads/20240615_sunset.jpg",
                    "image_remote_url": null,
                    "created_at": "2024-06-15T18:30:00"
                },
                {
                    "id": 2,
                    "album_id": 5,
                    "title": "Mountain View",
                    "image_local_uri": null,
                    "image_remote_url": "https://example.com/mountain.jpg",
                    "created_at": "2024-06-16T10:00:00"
                }
            ],
            "page": 1,
            "page_size": 20,
            "total": 2
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.getMemories(albumId = 5, page = 1, pageSize = 20)

        // Then
        assertEquals(2, result.items.size)
        assertEquals(1, result.page)
        assertEquals(20, result.pageSize)
        assertEquals(2, result.total)

        // First memory
        assertEquals(1, result.items[0].id)
        assertEquals(5, result.items[0].albumId)
        assertEquals("Beach Sunset", result.items[0].title)
        assertEquals("/uploads/20240615_sunset.jpg", result.items[0].imageLocalUri)
        assertNull(result.items[0].imageRemoteUrl)

        // Second memory
        assertEquals(2, result.items[1].id)
        assertEquals("Mountain View", result.items[1].title)
        assertNull(result.items[1].imageLocalUri)
        assertEquals("https://example.com/mountain.jpg", result.items[1].imageRemoteUrl)
    }

    @Test
    fun getMemories_decodesEmptyList() = runTest {
        // Given
        val json = """{
            "items": [],
            "page": 1,
            "page_size": 20,
            "total": 0
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.getMemories(albumId = 10, page = 1, pageSize = 20)

        // Then
        assertEquals(0, result.items.size)
        assertEquals(0, result.total)
    }

    @Test
    fun getMemories_sendsCorrectRequestWithPagination() = runTest {
        // Given
        val json = """{"items": [], "page": 3, "page_size": 10, "total": 0}"""
        mockApiClient.setResponse(json)

        // When
        gateway.getMemories(albumId = 7, page = 3, pageSize = 10)

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/albums/7/memories", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.GET, request?.method)
        assertEquals("3", request?.queryParams?.get("page"))
        assertEquals("10", request?.queryParams?.get("page_size"))
    }

    @Test
    fun uploadMemory_decodesMemoryResponse() = runTest {
        // Given - Backend returns MemoryOut schema
        val json = """{
            "id": 42,
            "album_id": 5,
            "title": "New Memory",
            "image_local_uri": "/uploads/20240620150000_photo.jpg",
            "image_remote_url": null,
            "created_at": "2024-06-20T15:00:00"
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.uploadMemory(
            albumId = 5,
            title = "New Memory",
            imageRemoteUrl = null,
            fileData = byteArrayOf(1, 2, 3, 4, 5),
            fileName = "photo.jpg",
            mimeType = "image/jpeg"
        )

        // Then
        assertEquals(42, result.id)
        assertEquals(5, result.albumId)
        assertEquals("New Memory", result.title)
        assertEquals("/uploads/20240620150000_photo.jpg", result.imageLocalUri)
        assertNull(result.imageRemoteUrl)
    }

    @Test
    fun uploadMemory_decodesMemoryResponseWithRemoteUrl() = runTest {
        // Given - Memory with remote URL instead of local file
        val json = """{
            "id": 50,
            "album_id": 3,
            "title": "Remote Image",
            "image_local_uri": null,
            "image_remote_url": "https://example.com/image.jpg",
            "created_at": "2024-06-20T16:00:00"
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.uploadMemory(
            albumId = 3,
            title = "Remote Image",
            imageRemoteUrl = "https://example.com/image.jpg",
            fileData = null,
            fileName = null,
            mimeType = null
        )

        // Then
        assertEquals(50, result.id)
        assertEquals("Remote Image", result.title)
        assertNull(result.imageLocalUri)
        assertEquals("https://example.com/image.jpg", result.imageRemoteUrl)
    }

    @Test
    fun uploadMemory_sendsCorrectRequest() = runTest {
        // Given
        val json = """{
            "id": 1,
            "album_id": 5,
            "title": "Test",
            "created_at": "2024-01-01T00:00:00"
        }"""
        mockApiClient.setResponse(json)

        // When
        gateway.uploadMemory(
            albumId = 5,
            title = "Test Memory",
            imageRemoteUrl = null,
            fileData = byteArrayOf(1, 2, 3),
            fileName = "test.jpg",
            mimeType = "image/jpeg"
        )

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/upload", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.POST, request?.method)
    }
}
