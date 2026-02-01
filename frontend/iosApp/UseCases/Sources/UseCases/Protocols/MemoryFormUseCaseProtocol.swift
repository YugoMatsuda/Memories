import Foundation
import Domains

public enum MemoryFormUseCaseModel {
    public enum CreateResult: Sendable {
        case success(Memory)
        case successPendingSync(Memory)
        case failure(Error)

        public enum Error: Sendable, Equatable {
            case networkError
            case imageStorageFailed
            case databaseError
            case unknown
        }
    }
}

public protocol MemoryFormUseCaseProtocol: Sendable {
    func createMemory(album: Album, title: String, imageData: Data) async -> MemoryFormUseCaseModel.CreateResult
}
