import Foundation

public enum APIError: Error {
    // Client Errors (4xx)
    case badRequest             // 400
    case invalidAPIToken        // 401
    case forbidden              // 403
    case notFound               // 404
    case validationError        // 422

    // Server Errors (5xx)
    case serverError            // 500
    case serviceUnavailable     // 503

    // Network / Response Errors
    case emptyResponse          // 204
    case networkError(Error)
    case decodingError(Error)
    case invalidURL
    case timeout

    // Unknown
    case unexpected(statusCode: Int?)
}
