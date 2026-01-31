import Foundation

public enum MemoryFormUseCaseModel {
    public enum CreateResult: Sendable {
        case success
        case failure(Error)

        public enum Error: Sendable, Equatable {
            case networkError
            case unknown
        }
    }
}

public protocol MemoryFormUseCaseProtocol: Sendable {
    func createMemory(albumId: Int, title: String, imageData: Data) async -> MemoryFormUseCaseModel.CreateResult
}
