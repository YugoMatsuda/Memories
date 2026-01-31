import Foundation

public protocol AuthenticatedAPIClientProtocol: APIClientProtocol {
    init(apiToken: String, baseURL: URL)
}
