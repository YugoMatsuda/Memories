import Foundation

public struct AvatarUploadRequest: APIRequestProtocol {
    public let fileData: Data
    public let fileName: String
    public let mimeType: String

    public let boundary = UUID().uuidString

    public init(
        fileData: Data,
        fileName: String,
        mimeType: String
    ) {
        self.fileData = fileData
        self.fileName = fileName
        self.mimeType = mimeType
    }

    public var path: String { "/me/avatar" }
    public var method: HTTPMethod { .post }
    public var headerType: HeaderType { .multipartFormData }
    public var queryItems: [URLQueryItem]? { nil }
    public var contentTypeOverride: String? { "multipart/form-data; boundary=\(boundary)" }

    public var httpBody: Data? {
        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")

        body.append("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
