import Foundation
@_exported import Shared

// Type alias for KMP SyncStatus (SKIE generates Swift enum as Shared.SyncStatus)
public typealias SyncStatus = Shared.SyncStatus

// MARK: - Extensions for Kotlin type (__SyncStatus)
extension Shared.__SyncStatus {
    /// Convert to Codable string representation for persistence
    public var rawValue: String {
        self.toSwiftEnum().rawValue
    }

    /// Create from string representation
    public static func from(rawValue: String) -> Shared.__SyncStatus {
        switch rawValue {
        case "synced": return Shared.__SyncStatus.synced as Shared.__SyncStatus
        case "pendingCreate": return Shared.__SyncStatus.pendingCreate as Shared.__SyncStatus
        case "pendingUpdate": return Shared.__SyncStatus.pendingUpdate as Shared.__SyncStatus
        case "syncing": return Shared.__SyncStatus.syncing as Shared.__SyncStatus
        case "failed": return Shared.__SyncStatus.failed as Shared.__SyncStatus
        default: return Shared.__SyncStatus.synced as Shared.__SyncStatus
        }
    }
}

// MARK: - Extensions for SKIE Swift enum (SyncStatus)
extension Shared.SyncStatus {
    /// Convert to Codable string representation for persistence
    public var rawValue: String {
        switch self {
        case .synced: return "synced"
        case .pendingCreate: return "pendingCreate"
        case .pendingUpdate: return "pendingUpdate"
        case .syncing: return "syncing"
        case .failed: return "failed"
        }
    }
}
