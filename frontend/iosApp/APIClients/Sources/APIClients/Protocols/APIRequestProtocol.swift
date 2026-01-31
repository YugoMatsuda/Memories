import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

public enum HeaderType: Sendable {
    case getJson
    case postJson
    case postURLEncoded
    case multipartFormData

    var contentType: String? {
        switch self {
        case .getJson:
            return nil
        case .postJson:
            return "application/json"
        case .postURLEncoded:
            return "application/x-www-form-urlencoded"
        case .multipartFormData:
            return nil // boundary is set separately
        }
    }
}

public protocol APIRequestProtocol: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var headerType: HeaderType { get }
    var httpBody: Data? { get }
    var queryItems: [URLQueryItem]? { get }
    var contentTypeOverride: String? { get }
}

public extension APIRequestProtocol {
    var contentTypeOverride: String? { nil }
}
