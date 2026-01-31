import Foundation

public struct PublicAPIClient: APIClientProtocol, Sendable {
    private let baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    public func send(_ apiRequest: some APIRequestProtocol) async throws -> Data {
        let request = try makeURLRequest(from: apiRequest)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpURLResponse = response as? HTTPURLResponse
            guard let statusCode = httpURLResponse?.statusCode else {
                throw APIError.unexpected(statusCode: nil)
            }
            switch statusCode {
            case 200, 201:
                return data
            case 204:
                throw APIError.emptyResponse
            case 400:
                throw APIError.badRequest
            case 401:
                throw APIError.invalidAPIToken
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 422:
                throw APIError.validationError
            case 500:
                throw APIError.serverError
            case 503:
                throw APIError.serviceUnavailable
            default:
                throw APIError.unexpected(statusCode: statusCode)
            }
        } catch {
            print("PublicAPIClient.send request:", apiRequest, "error:", error)
            throw error
        }
    }
}

// MARK: - private
private extension PublicAPIClient {
    func makeURLRequest(from apiRequest: some APIRequestProtocol) throws -> URLRequest {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.path += apiRequest.path
        if let queryItems = apiRequest.queryItems {
            urlComponents?.queryItems = queryItems
        }
        guard let url = urlComponents?.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 10.0
        )
        var headers: [String: String] = [
            "accept": "application/json"
        ]
        if let contentType = apiRequest.headerType.contentType {
            headers["Content-Type"] = contentType
        }

        request.httpMethod = apiRequest.method.rawValue
        request.httpBody = apiRequest.httpBody
        request.allHTTPHeaderFields = headers
        return request
    }
}
