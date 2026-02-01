import Foundation
import SwiftData

public protocol DomainConvertible where Self: PersistentModel {
    associatedtype Entity: Identifiable & Sendable & Hashable
    init(from entity: Entity)
    func update(from entity: Entity)
    func entity() -> Entity
}
