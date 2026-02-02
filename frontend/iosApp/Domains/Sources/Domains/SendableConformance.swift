import Foundation
import Shared

// MARK: - Sendable Conformances for KMP Types
// KMP types are thread-safe data classes, but don't automatically conform to Sendable.
// We add @unchecked Sendable since Kotlin data classes are immutable and safe to share.

extension Shared.Album: @unchecked @retroactive Sendable {}
extension Shared.Memory: @unchecked @retroactive Sendable {}
extension Shared.User: @unchecked @retroactive Sendable {}
extension Shared.AuthSession: @unchecked @retroactive Sendable {}
extension Shared.SyncOperation: @unchecked @retroactive Sendable {}
extension Shared.LocalId: @unchecked @retroactive Sendable {}
extension Shared.Timestamp: @unchecked @retroactive Sendable {}
extension Shared.__SyncStatus: @unchecked @retroactive Sendable {}
extension Shared.__EntityType: @unchecked @retroactive Sendable {}
extension Shared.__OperationType: @unchecked @retroactive Sendable {}
extension Shared.__SyncOperationStatus: @unchecked @retroactive Sendable {}
extension Shared.__MimeType: @unchecked @retroactive Sendable {}
