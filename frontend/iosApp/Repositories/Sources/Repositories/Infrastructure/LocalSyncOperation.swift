import Foundation
import SwiftData
import Domains
import Shared

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
        self.id = entity.id.uuid
        self.entityTypeRaw = entity.entityType.rawValue
        self.operationTypeRaw = entity.operationType.rawValue
        self.localId = entity.localId.uuid
        self.createdAt = entity.createdAt.date
        self.statusRaw = entity.status.rawValue
        self.errorMessage = entity.errorMessage
    }

    public func update(from entity: SyncOperation) {
        self.statusRaw = entity.status.rawValue
        self.errorMessage = entity.errorMessage
    }

    public func entity() -> SyncOperation {
        SyncOperation.create(
            id: id,
            entityType: Shared.__EntityType.from(rawValue: entityTypeRaw).toSwiftEnum(),
            operationType: Shared.__OperationType.from(rawValue: operationTypeRaw).toSwiftEnum(),
            localId: localId,
            createdAt: createdAt,
            status: Shared.__SyncOperationStatus.from(rawValue: statusRaw).toSwiftEnum(),
            errorMessage: errorMessage
        )
    }
}
