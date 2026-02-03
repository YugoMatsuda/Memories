package com.example.memoriesapp.gateway.impl

import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class AlbumGatewayImplTest {

    private val mockApiClient = MockApiClient()
    private val gateway = AlbumGatewayImpl(mockApiClient)

    @Test
    fun getAlbum_decodesAlbumResponse() = runTest {
        // Given - Backend returns AlbumOut schema
        val json = """{
            "id": 5,
            "title": "Summer Vacation 2024",
            "cover_image_url": "/uploads/cover_5.jpg",
            "created_at": "2024-06-15T10:30:00"
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.getAlbum(id = 5)

        // Then
        assertEquals(5, result.id)
        assertEquals("Summer Vacation 2024", result.title)
        assertEquals("/uploads/cover_5.jpg", result.coverImageUrl)
        assertEquals("2024-06-15T10:30:00", result.createdAt)
    }

    @Test
    fun getAlbum_decodesAlbumResponseWithNullCover() = runTest {
        // Given
        val json = """{
            "id": 3,
            "title": "No Cover Album",
            "cover_image_url": null,
            "created_at": "2024-01-01T00:00:00"
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.getAlbum(id = 3)

        // Then
        assertEquals(3, result.id)
        assertEquals("No Cover Album", result.title)
        assertNull(result.coverImageUrl)
    }

    @Test
    fun getAlbum_sendsCorrectRequest() = runTest {
        // Given
        val json = """{"id": 1, "title": "Test", "created_at": "2024-01-01T00:00:00"}"""
        mockApiClient.setResponse(json)

        // When
        gateway.getAlbum(id = 42)

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/albums/42", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.GET, request?.method)
    }

    @Test
    fun getAlbums_decodesPaginatedAlbumsResponse() = runTest {
        // Given - Backend returns PaginatedAlbums schema
        val json = """{
            "items": [
                {"id": 1, "title": "Album 1", "cover_image_url": null, "created_at": "2024-01-01T00:00:00"},
                {"id": 2, "title": "Album 2", "cover_image_url": "/uploads/cover.jpg", "created_at": "2024-01-02T00:00:00"}
            ],
            "page": 1,
            "page_size": 20,
            "total": 2
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.getAlbums(page = 1, pageSize = 20)

        // Then
        assertEquals(2, result.items.size)
        assertEquals(1, result.page)
        assertEquals(20, result.pageSize)
        assertEquals(2, result.total)
        assertEquals("Album 1", result.items[0].title)
        assertEquals("Album 2", result.items[1].title)
        assertEquals("/uploads/cover.jpg", result.items[1].coverImageUrl)
    }

    @Test
    fun getAlbums_decodesEmptyList() = runTest {
        // Given
        val json = """{
            "items": [],
            "page": 1,
            "page_size": 20,
            "total": 0
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.getAlbums(page = 1, pageSize = 20)

        // Then
        assertEquals(0, result.items.size)
        assertEquals(0, result.total)
    }

    @Test
    fun getAlbums_sendsCorrectRequestWithPagination() = runTest {
        // Given
        val json = """{"items": [], "page": 2, "page_size": 10, "total": 0}"""
        mockApiClient.setResponse(json)

        // When
        gateway.getAlbums(page = 2, pageSize = 10)

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/albums", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.GET, request?.method)
        assertEquals("2", request?.queryParams?.get("page"))
        assertEquals("10", request?.queryParams?.get("page_size"))
    }

    @Test
    fun createAlbum_decodesAlbumResponse() = runTest {
        // Given
        val json = """{
            "id": 10,
            "title": "New Album",
            "cover_image_url": null,
            "created_at": "2024-06-20T15:00:00"
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.createAlbum(title = "New Album", coverImageUrl = null)

        // Then
        assertEquals(10, result.id)
        assertEquals("New Album", result.title)
        assertNull(result.coverImageUrl)
    }

    @Test
    fun createAlbum_sendsCorrectRequest() = runTest {
        // Given
        val json = """{"id": 1, "title": "Test", "created_at": "2024-01-01T00:00:00"}"""
        mockApiClient.setResponse(json)

        // When
        gateway.createAlbum(title = "My Album", coverImageUrl = null)

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/albums", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.POST, request?.method)
    }

    @Test
    fun updateAlbum_decodesAlbumResponse() = runTest {
        // Given
        val json = """{
            "id": 5,
            "title": "Updated Title",
            "cover_image_url": "/uploads/new_cover.jpg",
            "created_at": "2024-01-01T00:00:00"
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.updateAlbum(albumId = 5, title = "Updated Title", coverImageUrl = null)

        // Then
        assertEquals(5, result.id)
        assertEquals("Updated Title", result.title)
    }

    @Test
    fun updateAlbum_sendsCorrectRequest() = runTest {
        // Given
        val json = """{"id": 5, "title": "Test", "created_at": "2024-01-01T00:00:00"}"""
        mockApiClient.setResponse(json)

        // When
        gateway.updateAlbum(albumId = 5, title = "New Title", coverImageUrl = null)

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/albums/5", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.PUT, request?.method)
    }

    @Test
    fun uploadCoverImage_decodesAlbumResponse() = runTest {
        // Given
        val json = """{
            "id": 7,
            "title": "Album with Cover",
            "cover_image_url": "/uploads/cover_7_20240620150000_photo.jpg",
            "created_at": "2024-01-01T00:00:00"
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.uploadCoverImage(
            albumId = 7,
            fileData = byteArrayOf(1, 2, 3, 4, 5),
            fileName = "photo.jpg",
            mimeType = "image/jpeg"
        )

        // Then
        assertEquals(7, result.id)
        assertEquals("/uploads/cover_7_20240620150000_photo.jpg", result.coverImageUrl)
    }

    @Test
    fun uploadCoverImage_sendsCorrectRequest() = runTest {
        // Given
        val json = """{"id": 3, "title": "Test", "created_at": "2024-01-01T00:00:00"}"""
        mockApiClient.setResponse(json)

        // When
        gateway.uploadCoverImage(
            albumId = 3,
            fileData = byteArrayOf(1, 2, 3),
            fileName = "cover.jpg",
            mimeType = "image/jpeg"
        )

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/albums/3/cover", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.POST, request?.method)
    }
}
