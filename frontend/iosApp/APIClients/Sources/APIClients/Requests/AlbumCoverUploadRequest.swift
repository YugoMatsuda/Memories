import Foundation

public struct AlbumCoverUploadRequest: APIRequestProtocol {
    public let albumId: Int
    public let fileData: Data
    public let fileName: String
    public let mimeType: String
    public let boundary = UUID().uuidString

    public init(albumId: Int, fileData: Data, fileName: String, mimeType: String) {
        self.albumId = albumId
        self.fileData = fileData
        self.fileName = fileName
        self.mimeType = mimeType
    }

    public var path: String { "/albums/\(albumId)/cover" }
    public var method: HTTPMethod { .post }
    public var headerType: HeaderType { .multipartFormData }
    public var queryItems: [URLQueryItem]? { nil }
    public var contentTypeOverride: String? { "multipart/form-data; boundary=\(boundary)" }

    public var httpBody: Data? {
        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\(lineBreak)")
        body.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
        body.append(fileData)
        body.append("\(lineBreak)")
        body.append("--\(boundary)--\(lineBreak)")

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
