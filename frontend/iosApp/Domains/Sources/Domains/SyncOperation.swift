import Foundation

public struct SyncOperation: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let entityType: EntityType
    public let operationType: OperationType
    public let localId: UUID
    public let createdAt: Date
    public var status: SyncOperationStatus
    public var errorMessage: String?

    public init(
        id: UUID,
        entityType: EntityType,
        operationType: OperationType,
        localId: UUID,
        createdAt: Date,
        status: SyncOperationStatus,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.entityType = entityType
        self.operationType = operationType
        self.localId = localId
        self.createdAt = createdAt
        self.status = status
        self.errorMessage = errorMessage
    }
}

public enum EntityType: String, Codable, Sendable {
    case album
    case memory
    case user
}

public enum OperationType: String, Codable, Sendable {
    case create
    case update
}

public enum SyncOperationStatus: String, Codable, Sendable {
    case pending
    case inProgress
    case failed
}
