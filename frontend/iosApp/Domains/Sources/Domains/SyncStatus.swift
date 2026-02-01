import Foundation

public enum SyncStatus: String, Codable, Sendable {
    case synced
    case pendingCreate
    case pendingUpdate
    case syncing
    case failed
}
