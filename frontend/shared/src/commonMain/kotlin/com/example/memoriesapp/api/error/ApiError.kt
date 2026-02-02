package com.example.memoriesapp.api.error

/**
 * API error types matching iOS APIError
 */
sealed class ApiError : Exception() {
    // Client errors (4xx)
    data object BadRequest : ApiError()
    data object InvalidApiToken : ApiError()
    data object Forbidden : ApiError()
    data object NotFound : ApiError()
    data object ValidationError : ApiError()

    // Server errors (5xx)
    data object ServerError : ApiError()
    data object ServiceUnavailable : ApiError()

    // Network/Response errors
    data object EmptyResponse : ApiError()
    data class NetworkError(override val cause: Throwable) : ApiError()
    data class DecodingError(override val cause: Throwable) : ApiError()
    data object InvalidUrl : ApiError()
    data object Timeout : ApiError()
    data class Unexpected(val statusCode: Int?) : ApiError()

    companion object {
        fun fromStatusCode(statusCode: Int): ApiError = when (statusCode) {
            204 -> EmptyResponse
            400 -> BadRequest
            401 -> InvalidApiToken
            403 -> Forbidden
            404 -> NotFound
            422 -> ValidationError
            500 -> ServerError
            503 -> ServiceUnavailable
            else -> Unexpected(statusCode)
        }
    }
}
