import Foundation

public final class ImageStorageRepository: ImageStorageRepositoryProtocol, @unchecked Sendable {
    private let userId: Int
    private let baseDirectory: URL

    public init(userId: Int) {
        self.userId = userId
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.baseDirectory = documents
            .appendingPathComponent("images", isDirectory: true)
            .appendingPathComponent("\(userId)", isDirectory: true)
    }

    private func ensureDirectoryExists(for entity: ImageEntityType) throws -> URL {
        let dir = baseDirectory.appendingPathComponent(entity.rawValue, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        } catch {
            throw ImageStorageError.directoryCreationFailed
        }
    }

    public func save(_ data: Data, entity: ImageEntityType, localId: UUID) throws -> String {
        let dir = try ensureDirectoryExists(for: entity)
        let path = dir.appendingPathComponent("\(localId.uuidString).jpg").path
        let url = URL(fileURLWithPath: path)
        do {
            try data.write(to: url)
            return path
        } catch {
            throw ImageStorageError.saveFailed(error)
        }
    }

    public func get(entity: ImageEntityType, localId: UUID) throws -> Data {
        let path = getPath(entity: entity, localId: localId)
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            throw ImageStorageError.fileNotFound
        }
        return data
    }

    public func delete(entity: ImageEntityType, localId: UUID) {
        let path = getPath(entity: entity, localId: localId)
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
    }

    public func getPath(entity: ImageEntityType, localId: UUID) -> String {
        baseDirectory
            .appendingPathComponent(entity.rawValue, isDirectory: true)
            .appendingPathComponent("\(localId.uuidString).jpg")
            .path
    }
}
