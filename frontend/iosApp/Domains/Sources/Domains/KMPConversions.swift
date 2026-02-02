import Foundation
import Shared

// MARK: - LocalId <-> UUID Conversion

extension Shared.LocalId {
    /// Convert KMP LocalId to Swift UUID
    public var uuid: UUID {
        UUID(uuidString: description()) ?? UUID()
    }

    /// Create LocalId from Swift UUID
    public static func from(uuid: UUID) -> Shared.LocalId {
        Shared.LocalId.companion.fromString(value: uuid.uuidString)
    }
}

extension UUID {
    /// Convert Swift UUID to KMP LocalId
    public var localId: Shared.LocalId {
        Shared.LocalId.companion.fromString(value: uuidString)
    }
}

// MARK: - Timestamp <-> Date Conversion

extension Shared.Timestamp {
    /// Convert KMP Timestamp to Swift Date
    public var date: Date {
        Date(timeIntervalSince1970: Double(epochMillis) / 1000.0)
    }

    /// Create Timestamp from Swift Date
    public static func from(date: Date) -> Shared.Timestamp {
        Shared.Timestamp.companion.fromEpochMillis(millis: Int64(date.timeIntervalSince1970 * 1000))
    }
}

extension Date {
    /// Convert Swift Date to KMP Timestamp
    public var timestamp: Shared.Timestamp {
        Shared.Timestamp.companion.fromEpochMillis(millis: Int64(timeIntervalSince1970 * 1000))
    }
}

// MARK: - URL <-> String Conversion

extension URL {
    /// Convert URL to String for KMP
    public var kmpString: String {
        absoluteString
    }
}

extension String {
    /// Convert String to URL (optional)
    public var url: URL? {
        URL(string: self)
    }

    /// Convert local file path String to URL
    public var fileURL: URL {
        URL(fileURLWithPath: self)
    }
}
