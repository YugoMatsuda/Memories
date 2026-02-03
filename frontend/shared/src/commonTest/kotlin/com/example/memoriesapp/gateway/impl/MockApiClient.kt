package com.example.memoriesapp.gateway.impl

import com.example.memoriesapp.api.client.ApiClient
import com.example.memoriesapp.api.client.ApiRequest

/**
 * Mock ApiClient for testing Gateway implementations.
 * Returns predefined JSON responses.
 */
class MockApiClient : ApiClient {
    private var responseJson: String = ""
    private var capturedRequest: ApiRequest? = null

    /**
     * Set the JSON response to return on next sendRequest call
     */
    fun setResponse(json: String) {
        responseJson = json
    }

    /**
     * Get the last captured request
     */
    fun getCapturedRequest(): ApiRequest? = capturedRequest

    override suspend fun sendRequest(request: ApiRequest): ByteArray {
        capturedRequest = request
        return responseJson.encodeToByteArray()
    }
}
