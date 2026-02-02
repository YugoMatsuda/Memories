import Foundation
import Shared

// Type alias for KMP MimeType (SKIE generates Swift enum as Shared.MimeType)
public typealias MimeType = Shared.MimeType

// MARK: - Swift-friendly extensions

extension Shared.MimeType {
    /// Generate filename with Swift UUID
    public func fileName(for id: UUID) -> String {
        fileName(id: Shared.LocalId.from(uuid: id))
    }
}
