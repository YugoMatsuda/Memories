import Foundation
import Domains
@preconcurrency import Shared

/// Swift implementation of ImageStorageRepositoryBridge
public final class ImageStorageRepositoryBridgeImpl: Shared.ImageStorageRepositoryBridge, @unchecked Sendable {
    private let repository: ImageStorageRepositoryProtocol

    public init(repository: ImageStorageRepositoryProtocol) {
        self.repository = repository
    }

    public func save(data: Shared.KotlinByteArray, entity: Shared.ImageEntityType, localId: Shared.LocalId) -> String {
        let swiftData = data.toData()
        let swiftEntity = entity.toSwift()
        return (try? repository.save(swiftData, entity: swiftEntity, localId: localId.uuid)) ?? ""
    }

    public func get(entity: Shared.ImageEntityType, localId: Shared.LocalId) -> Shared.KotlinByteArray {
        let swiftEntity = entity.toSwift()
        guard let data = try? repository.get(entity: swiftEntity, localId: localId.uuid) else {
            return Shared.KotlinByteArray(size: 0)
        }
        return Shared.KotlinByteArray.from(data: data)
    }

    public func delete(entity: Shared.ImageEntityType, localId: Shared.LocalId) {
        let swiftEntity = entity.toSwift()
        repository.delete(entity: swiftEntity, localId: localId.uuid)
    }

    public func getPath(entity: Shared.ImageEntityType, localId: Shared.LocalId) -> String {
        let swiftEntity = entity.toSwift()
        return repository.getPath(entity: swiftEntity, localId: localId.uuid)
    }
}

// MARK: - Conversion Helpers

extension Shared.ImageEntityType {
    func toSwift() -> ImageEntityType {
        switch self {
        case .albumCover: return .albumCover
        case .memory: return .memory
        case .avatar: return .avatar
        default: return .memory
        }
    }
}

extension Shared.KotlinByteArray {
    func toData() -> Data {
        var bytes = [UInt8]()
        for i in 0..<size {
            bytes.append(UInt8(bitPattern: get(index: i)))
        }
        return Data(bytes)
    }
}
