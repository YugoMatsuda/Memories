package com.example.memoriesapp.gateway.impl

import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

class AuthGatewayImplTest {

    private val mockApiClient = MockApiClient()
    private val gateway = AuthGatewayImpl(mockApiClient)

    @Test
    fun login_decodesTokenResponse() = runTest {
        // Given - Backend returns: {"token": "test-token-123", "user_id": 42}
        val json = """{"token": "test-token-123", "user_id": 42}"""
        mockApiClient.setResponse(json)

        // When
        val result = gateway.login("demo", "password")

        // Then
        assertEquals("test-token-123", result.token)
        assertEquals(42, result.userId)
    }

    @Test
    fun login_sendsCorrectRequest() = runTest {
        // Given
        val json = """{"token": "token", "user_id": 1}"""
        mockApiClient.setResponse(json)

        // When
        gateway.login("testuser", "testpass")

        // Then
        val request = mockApiClient.getCapturedRequest()
        assertEquals("/auth/login", request?.path)
        assertEquals(com.example.memoriesapp.api.client.HttpMethod.POST, request?.method)
    }
}
