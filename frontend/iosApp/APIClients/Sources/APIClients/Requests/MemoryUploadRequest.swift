import Foundation

public struct MemoryUploadRequest: APIRequestProtocol {
    public let albumId: Int
    public let title: String
    public let imageRemoteUrl: String?
    public let fileData: Data?
    public let fileName: String?
    public let mimeType: String?

    public let boundary = UUID().uuidString

    public init(
        albumId: Int,
        title: String,
        imageRemoteUrl: String? = nil,
        fileData: Data? = nil,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        self.albumId = albumId
        self.title = title
        self.imageRemoteUrl = imageRemoteUrl
        self.fileData = fileData
        self.fileName = fileName
        self.mimeType = mimeType
    }

    public var path: String { "/upload" }
    public var method: HTTPMethod { .post }
    public var headerType: HeaderType { .multipartFormData }
    public var queryItems: [URLQueryItem]? { nil }
    public var contentTypeOverride: String? { "multipart/form-data; boundary=\(boundary)" }

    public var httpBody: Data? {
        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"album_id\"\r\n\r\n")
        body.append("\(albumId)\r\n")

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n")
        body.append("\(title)\r\n")

        if let imageRemoteUrl {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"image_remote_url\"\r\n\r\n")
            body.append("\(imageRemoteUrl)\r\n")
        }

        if let fileData, let fileName, let mimeType {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
            body.append("Content-Type: \(mimeType)\r\n\r\n")
            body.append(fileData)
            body.append("\r\n")
        }

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
