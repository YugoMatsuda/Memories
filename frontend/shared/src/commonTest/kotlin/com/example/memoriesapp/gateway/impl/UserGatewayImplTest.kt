package com.example.memoriesapp.gateway.impl

import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class UserGatewayImplTest {

    private val mockApiClient = MockApiClient()
    private val gateway = UserGatewayImpl(mockApiClient)

    @Test
    fun getUser_decodesUserResponse() = runTest {
        // Given - Backend returns UserOut schema
        val json = """{
            "id": 1,
            "name": "Demo User",
            "username": "demo",
            "birthday": "1990-05-15",
            "avatar_url": "/uploads/avatar_1.jpg"
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.getUser()

        // Then
        assertEquals(1, result.id)
        assertEquals("Demo User", result.name)
        assertEquals("demo", result.username)
        assertEquals("1990-05-15", result.birthday)
        assertEquals("/uploads/avatar_1.jpg", result.avatarUrl)
    }

    @Test
    fun getUser_decodesUserResponseWithNullFields() = runTest {
        // Given - Backend returns UserOut with null optional fields
        val json = """{
            "id": 2,
            "name": "Test User",
            "username": "test",
            "birthday": null,
            "avatar_url": null
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.getUser()

        // Then
        assertEquals(2, result.id)
        assertEquals("Test User", result.name)
        assertEquals("test", result.username)
        assertNull(result.birthday)
        assertNull(result.avatarUrl)
    }

    @Test
    fun getUser_sendsCorrectRequest() = runTest {
        // Given
        val json = """{"id": 1, "name": "User", "username": "user"}"""
        mockApiClient.setResponse(json)

        // When
        gateway.getUser()

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/me", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.GET, request?.method)
    }

    @Test
    fun updateUser_decodesUserResponse() = runTest {
        // Given
        val json = """{
            "id": 1,
            "name": "Updated Name",
            "username": "demo",
            "birthday": "1995-01-01",
            "avatar_url": null
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.updateUser(name = "Updated Name", birthday = "1995-01-01", avatarUrl = null)

        // Then
        assertEquals("Updated Name", result.name)
        assertEquals("1995-01-01", result.birthday)
    }

    @Test
    fun updateUser_sendsCorrectRequest() = runTest {
        // Given
        val json = """{"id": 1, "name": "User", "username": "user"}"""
        mockApiClient.setResponse(json)

        // When
        gateway.updateUser(name = "New Name", birthday = null, avatarUrl = null)

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/me", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.PUT, request?.method)
    }

    @Test
    fun uploadAvatar_decodesUserResponse() = runTest {
        // Given
        val json = """{
            "id": 1,
            "name": "Demo User",
            "username": "demo",
            "birthday": null,
            "avatar_url": "/uploads/avatar_1_20240101120000_test.jpg"
        }"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.uploadAvatar(
            fileData = byteArrayOf(1, 2, 3),
            fileName = "test.jpg",
            mimeType = "image/jpeg"
        )

        // Then
        assertEquals("/uploads/avatar_1_20240101120000_test.jpg", result.avatarUrl)
    }

    @Test
    fun uploadAvatar_sendsCorrectRequest() = runTest {
        // Given
        val json = """{"id": 1, "name": "User", "username": "user"}"""
        mockApiClient.setResponse(json)

        // When
        gateway.uploadAvatar(
            fileData = byteArrayOf(1, 2, 3),
            fileName = "avatar.jpg",
            mimeType = "image/jpeg"
        )

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/me/avatar", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.POST, request?.method)
    }
}
