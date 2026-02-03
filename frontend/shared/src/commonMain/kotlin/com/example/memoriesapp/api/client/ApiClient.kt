package com.example.memoriesapp.api.client

import com.example.memoriesapp.api.error.ApiError
import io.ktor.client.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.client.request.forms.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

/**
 * HTTP method enum
 */
enum class HttpMethod {
    GET, POST, PUT
}

/**
 * API request interface
 */
interface ApiRequest {
    val path: String
    val method: HttpMethod
    val headers: Map<String, String>
        get() = emptyMap()
    val body: Any?
        get() = null
    val queryParams: Map<String, String>
        get() = emptyMap()
}

/**
 * Multipart form data for file uploads
 */
data class MultipartFormField(
    val name: String,
    val value: String
)

data class MultipartFileField(
    val name: String,
    val fileName: String,
    val contentType: String,
    val data: ByteArray
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other == null || this::class != other::class) return false
        other as MultipartFileField
        if (name != other.name) return false
        if (fileName != other.fileName) return false
        if (contentType != other.contentType) return false
        if (!data.contentEquals(other.data)) return false
        return true
    }

    override fun hashCode(): Int {
        var result = name.hashCode()
        result = 31 * result + fileName.hashCode()
        result = 31 * result + contentType.hashCode()
        result = 31 * result + data.contentHashCode()
        return result
    }
}

/**
 * Multipart form data request
 */
interface MultipartApiRequest : ApiRequest {
    val formFields: List<MultipartFormField>
        get() = emptyList()
    val fileFields: List<MultipartFileField>
        get() = emptyList()
}

/**
 * API Client interface
 */
interface ApiClient {
    suspend fun sendRequest(request: ApiRequest): ByteArray
}

/**
 * Public API client for unauthenticated requests
 */
class PublicApiClient(
    private val baseUrl: String
) : ApiClient {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val httpClient = HttpClient {
        install(ContentNegotiation) {
            json(json)
        }
    }

    override suspend fun sendRequest(request: ApiRequest): ByteArray {
        return try {
            val response = executeRequest(request, null)
            handleResponse(response)
        } catch (e: Exception) {
            throw when (e) {
                is ApiError -> e
                else -> ApiError.NetworkError(e)
            }
        }
    }

    private suspend fun executeRequest(request: ApiRequest, authToken: String?): HttpResponse {
        return httpClient.request {
            url {
                takeFrom(baseUrl)
                appendPathSegments(request.path)
                request.queryParams.forEach { (key, value) ->
                    parameters.append(key, value)
                }
            }
            this.method = when (request.method) {
                HttpMethod.GET -> io.ktor.http.HttpMethod.Get
                HttpMethod.POST -> io.ktor.http.HttpMethod.Post
                HttpMethod.PUT -> io.ktor.http.HttpMethod.Put
            }
            headers {
                append(HttpHeaders.Accept, ContentType.Application.Json.toString())
                authToken?.let { append(HttpHeaders.Authorization, "Bearer $it") }
                request.headers.forEach { (key, value) ->
                    append(key, value)
                }
            }
            when (request) {
                is MultipartApiRequest -> {
                    setBody(MultiPartFormDataContent(formData {
                        request.formFields.forEach { field ->
                            append(field.name, field.value)
                        }
                        request.fileFields.forEach { file ->
                            append(file.name, file.data, Headers.build {
                                append(HttpHeaders.ContentDisposition, "filename=\"${file.fileName}\"")
                                append(HttpHeaders.ContentType, file.contentType)
                            })
                        }
                    }))
                }
                else -> {
                    request.body?.let {
                        contentType(ContentType.Application.Json)
                        setBody(it)
                    }
                }
            }
        }
    }

    private suspend fun handleResponse(response: HttpResponse): ByteArray {
        return when (response.status.value) {
            in 200..299 -> {
                if (response.status.value == 204) {
                    throw ApiError.EmptyResponse
                }
                response.readRawBytes()
            }
            else -> throw ApiError.fromStatusCode(response.status.value)
        }
    }
}

/**
 * Authenticated API client for protected requests
 */
class AuthenticatedApiClient(
    private val baseUrl: String,
    private val apiToken: String
) : ApiClient {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val httpClient = HttpClient {
        install(ContentNegotiation) {
            json(json)
        }
        install(HttpTimeout) {
            requestTimeoutMillis = 60000
            connectTimeoutMillis = 30000
            socketTimeoutMillis = 60000
        }
        install(HttpRequestRetry) {
            retryOnServerErrors(maxRetries = 3)
            retryOnException(maxRetries = 3, retryOnTimeout = true)
            exponentialDelay()
        }
    }

    override suspend fun sendRequest(request: ApiRequest): ByteArray {
        return try {
            val response = executeRequest(request)
            handleResponse(response)
        } catch (e: Exception) {
            throw when (e) {
                is ApiError -> e
                else -> ApiError.NetworkError(e)
            }
        }
    }

    private suspend fun executeRequest(request: ApiRequest): HttpResponse {
        return httpClient.request {
            url {
                takeFrom(baseUrl)
                appendPathSegments(request.path)
                request.queryParams.forEach { (key, value) ->
                    parameters.append(key, value)
                }
            }
            this.method = when (request.method) {
                HttpMethod.GET -> io.ktor.http.HttpMethod.Get
                HttpMethod.POST -> io.ktor.http.HttpMethod.Post
                HttpMethod.PUT -> io.ktor.http.HttpMethod.Put
            }
            headers {
                append(HttpHeaders.Accept, ContentType.Application.Json.toString())
                append(HttpHeaders.Authorization, "Bearer $apiToken")
                request.headers.forEach { (key, value) ->
                    append(key, value)
                }
            }
            when (request) {
                is MultipartApiRequest -> {
                    setBody(MultiPartFormDataContent(formData {
                        request.formFields.forEach { field ->
                            append(field.name, field.value)
                        }
                        request.fileFields.forEach { file ->
                            append(file.name, file.data, Headers.build {
                                append(HttpHeaders.ContentDisposition, "filename=\"${file.fileName}\"")
                                append(HttpHeaders.ContentType, file.contentType)
                            })
                        }
                    }))
                }
                else -> {
                    request.body?.let {
                        contentType(ContentType.Application.Json)
                        setBody(it)
                    }
                }
            }
        }
    }

    private suspend fun handleResponse(response: HttpResponse): ByteArray {
        return when (response.status.value) {
            in 200..299 -> {
                if (response.status.value == 204) {
                    throw ApiError.EmptyResponse
                }
                response.readRawBytes()
            }
            else -> throw ApiError.fromStatusCode(response.status.value)
        }
    }
}
