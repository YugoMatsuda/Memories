import Foundation

public enum ImageEntityType: String, Sendable {
    case albumCover = "albums"
    case memory = "memories"
    case avatar = "avatars"
}

public enum ImageStorageError: Error {
    case directoryCreationFailed
    case saveFailed(Error)
    case fileNotFound
}

public protocol ImageStorageRepositoryProtocol: Sendable {
    func save(_ data: Data, entity: ImageEntityType, localId: UUID) throws -> String
    func get(entity: ImageEntityType, localId: UUID) throws -> Data
    func delete(entity: ImageEntityType, localId: UUID)
    func getPath(entity: ImageEntityType, localId: UUID) -> String
}
