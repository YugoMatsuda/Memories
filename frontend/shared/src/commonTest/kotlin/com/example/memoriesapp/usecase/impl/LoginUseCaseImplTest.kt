package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.TokenResponse
import com.example.memoriesapp.gateway.mock.MockAuthGateway
import com.example.memoriesapp.repository.mock.MockAuthSessionRepository
import com.example.memoriesapp.usecase.LoginError
import com.example.memoriesapp.usecase.LoginResult
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull

class LoginUseCaseImplTest {

    private val mockAuthGateway = MockAuthGateway()
    private val mockAuthSessionRepository = MockAuthSessionRepository()
    private val useCase = LoginUseCaseImpl(mockAuthGateway, mockAuthSessionRepository)

    @Test
    fun login_success_returnsSuccessWithSession() = runTest {
        mockAuthGateway.setResponse(TokenResponse(token = "test-token", userId = 42))

        val result = useCase.login("demo", "password")

        assertIs<LoginResult.Success>(result)
        assertEquals("test-token", result.session.token)
        assertEquals(42, result.session.userId)
    }

    @Test
    fun login_success_savesSessionToRepository() = runTest {
        mockAuthGateway.setResponse(TokenResponse(token = "saved-token", userId = 100))

        useCase.login("user", "pass")

        val savedSession = mockAuthSessionRepository.getSavedSession()
        assertNotNull(savedSession)
        assertEquals("saved-token", savedSession.token)
        assertEquals(100, savedSession.userId)
    }

    @Test
    fun login_success_passesCredentialsToGateway() = runTest {
        mockAuthGateway.setResponse(TokenResponse(token = "token", userId = 1))

        useCase.login("testuser", "testpass")

        val (username, password) = mockAuthGateway.getCapturedCredentials()
        assertEquals("testuser", username)
        assertEquals("testpass", password)
    }

    @Test
    fun login_invalidCredentials_returnsInvalidCredentialsError() = runTest {
        mockAuthGateway.setError(ApiError.InvalidApiToken)

        val result = useCase.login("wrong", "credentials")

        assertIs<LoginResult.Failure>(result)
        assertEquals(LoginError.INVALID_CREDENTIALS, result.error)
    }

    @Test
    fun login_forbidden_returnsInvalidCredentialsError() = runTest {
        mockAuthGateway.setError(ApiError.Forbidden)

        val result = useCase.login("user", "pass")

        assertIs<LoginResult.Failure>(result)
        assertEquals(LoginError.INVALID_CREDENTIALS, result.error)
    }

    @Test
    fun login_networkError_returnsNetworkError() = runTest {
        mockAuthGateway.setError(ApiError.NetworkError(Exception("Connection failed")))

        val result = useCase.login("user", "pass")

        assertIs<LoginResult.Failure>(result)
        assertEquals(LoginError.NETWORK_ERROR, result.error)
    }

    @Test
    fun login_timeout_returnsNetworkError() = runTest {
        mockAuthGateway.setError(ApiError.Timeout)

        val result = useCase.login("user", "pass")

        assertIs<LoginResult.Failure>(result)
        assertEquals(LoginError.NETWORK_ERROR, result.error)
    }

    @Test
    fun login_serverError_returnsServerError() = runTest {
        mockAuthGateway.setError(ApiError.ServerError)

        val result = useCase.login("user", "pass")

        assertIs<LoginResult.Failure>(result)
        assertEquals(LoginError.SERVER_ERROR, result.error)
    }

    @Test
    fun login_serviceUnavailable_returnsServerError() = runTest {
        mockAuthGateway.setError(ApiError.ServiceUnavailable)

        val result = useCase.login("user", "pass")

        assertIs<LoginResult.Failure>(result)
        assertEquals(LoginError.SERVER_ERROR, result.error)
    }

    @Test
    fun login_unknownApiError_returnsUnknownError() = runTest {
        mockAuthGateway.setError(ApiError.BadRequest)

        val result = useCase.login("user", "pass")

        assertIs<LoginResult.Failure>(result)
        assertEquals(LoginError.UNKNOWN, result.error)
    }

    @Test
    fun login_unexpectedException_returnsUnknownError() = runTest {
        mockAuthGateway.setError(RuntimeException("Unexpected"))

        val result = useCase.login("user", "pass")

        assertIs<LoginResult.Failure>(result)
        assertEquals(LoginError.UNKNOWN, result.error)
    }
}
