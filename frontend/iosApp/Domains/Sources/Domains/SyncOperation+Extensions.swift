import Foundation
import Shared

// Type aliases for KMP types
// Note: SKIE generates Swift enums (Shared.EnumName) from Kotlin enums (Shared.__EnumName)
public typealias SyncOperation = Shared.SyncOperation
public typealias EntityType = Shared.EntityType
public typealias OperationType = Shared.OperationType
public typealias SyncOperationStatus = Shared.SyncOperationStatus

// MARK: - Swift-friendly extensions for SyncOperation

extension Shared.SyncOperation {
    /// ID as Swift UUID
    public var idUUID: UUID {
        id.uuid
    }

    /// LocalId as Swift UUID
    public var localIdUUID: UUID {
        localId.uuid
    }

    /// CreatedAt as Swift Date
    public var createdAtDate: Date {
        createdAt.date
    }

    /// Create SyncOperation with Swift types
    public static func create(
        id: UUID,
        entityType: Shared.EntityType,
        operationType: Shared.OperationType,
        localId: UUID,
        createdAt: Date,
        status: Shared.SyncOperationStatus,
        errorMessage: String? = nil
    ) -> Shared.SyncOperation {
        Shared.SyncOperation(
            id: Shared.LocalId.from(uuid: id),
            entityType: entityType,
            operationType: operationType,
            localId: Shared.LocalId.from(uuid: localId),
            createdAt: Shared.Timestamp.from(date: createdAt),
            status: status,
            errorMessage: errorMessage
        )
    }

    /// Copy helper for immutable updates
    public func with(
        status: Shared.SyncOperationStatus? = nil,
        errorMessage: String?? = nil
    ) -> Shared.SyncOperation {
        let newErrorMessage: String?
        if let errorOpt = errorMessage {
            newErrorMessage = errorOpt
        } else {
            newErrorMessage = self.errorMessage
        }

        return Shared.SyncOperation(
            id: self.id,
            entityType: self.entityType,
            operationType: self.operationType,
            localId: self.localId,
            createdAt: self.createdAt,
            status: status ?? self.status,
            errorMessage: newErrorMessage
        )
    }
}

// MARK: - Protocol Conformances
// Note: Hashable and Equatable are inherited from Kotlin/NSObject

extension Shared.SyncOperation: @retroactive Identifiable {}

// MARK: - Enum raw values for persistence

extension Shared.__EntityType {
    public var rawValue: String {
        self.toSwiftEnum().rawValue
    }

    public static func from(rawValue: String) -> Shared.__EntityType {
        switch rawValue {
        case "album": return Shared.__EntityType.album as Shared.__EntityType
        case "memory": return Shared.__EntityType.memory as Shared.__EntityType
        case "user": return Shared.__EntityType.user as Shared.__EntityType
        default: return Shared.__EntityType.album as Shared.__EntityType
        }
    }
}

extension Shared.__OperationType {
    public var rawValue: String {
        self.toSwiftEnum().rawValue
    }

    public static func from(rawValue: String) -> Shared.__OperationType {
        switch rawValue {
        case "create": return Shared.__OperationType.create as Shared.__OperationType
        case "update": return Shared.__OperationType.update as Shared.__OperationType
        default: return Shared.__OperationType.create as Shared.__OperationType
        }
    }
}

extension Shared.__SyncOperationStatus {
    public var rawValue: String {
        self.toSwiftEnum().rawValue
    }

    public static func from(rawValue: String) -> Shared.__SyncOperationStatus {
        switch rawValue {
        case "pending": return Shared.__SyncOperationStatus.pending as Shared.__SyncOperationStatus
        case "inProgress": return Shared.__SyncOperationStatus.inProgress as Shared.__SyncOperationStatus
        case "failed": return Shared.__SyncOperationStatus.failed as Shared.__SyncOperationStatus
        default: return Shared.__SyncOperationStatus.pending as Shared.__SyncOperationStatus
        }
    }
}

// MARK: - Extensions for SKIE Swift enums

extension Shared.EntityType {
    public var rawValue: String {
        switch self {
        case .album: return "album"
        case .memory: return "memory"
        case .user: return "user"
        }
    }
}

extension Shared.OperationType {
    public var rawValue: String {
        switch self {
        case .create: return "create"
        case .update: return "update"
        }
    }
}

extension Shared.SyncOperationStatus {
    public var rawValue: String {
        switch self {
        case .pending: return "pending"
        case .inProgress: return "inProgress"
        case .failed: return "failed"
        }
    }
}
