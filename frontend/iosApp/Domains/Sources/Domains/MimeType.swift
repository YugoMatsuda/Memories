import Foundation

public enum MimeType: String, Sendable {
    case jpeg = "image/jpeg"

    public var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        }
    }

    public func fileName(for id: UUID) -> String {
        "\(id).\(fileExtension)"
    }
}
