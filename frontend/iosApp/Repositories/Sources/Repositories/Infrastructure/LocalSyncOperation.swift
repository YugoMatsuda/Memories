import Foundation
import SwiftData
import Domains

@Model
public final class LocalSyncOperation: DomainConvertible {
    public typealias Entity = SyncOperation

    @Attribute(.unique)
    public var id: UUID

    public var entityTypeRaw: String
    public var operationTypeRaw: String
    public var localId: UUID
    public var createdAt: Date
    public var statusRaw: String
    public var errorMessage: String?

    // MARK: - DomainConvertible

    public required init(from entity: SyncOperation) {
        self.id = entity.id
        self.entityTypeRaw = entity.entityType.rawValue
        self.operationTypeRaw = entity.operationType.rawValue
        self.localId = entity.localId
        self.createdAt = entity.createdAt
        self.statusRaw = entity.status.rawValue
        self.errorMessage = entity.errorMessage
    }

    public func update(from entity: SyncOperation) {
        self.statusRaw = entity.status.rawValue
        self.errorMessage = entity.errorMessage
    }

    public func entity() -> SyncOperation {
        SyncOperation(
            id: id,
            entityType: EntityType(rawValue: entityTypeRaw) ?? .album,
            operationType: OperationType(rawValue: operationTypeRaw) ?? .create,
            localId: localId,
            createdAt: createdAt,
            status: SyncOperationStatus(rawValue: statusRaw) ?? .pending,
            errorMessage: errorMessage
        )
    }
}
