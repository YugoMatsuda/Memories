import Foundation
import APIGateways

public struct MemoryFormUseCase: MemoryFormUseCaseProtocol, Sendable {
    private let memoryGateway: MemoryGatewayProtocol

    public init(memoryGateway: MemoryGatewayProtocol) {
        self.memoryGateway = memoryGateway
    }

    public func createMemory(albumId: Int, title: String, imageData: Data) async -> MemoryFormUseCaseModel.CreateResult {
        let fileName = "\(UUID().uuidString).jpg"
        let mimeType = "image/jpeg"

        do {
            _ = try await memoryGateway.uploadMemory(
                albumId: albumId,
                title: title,
                imageRemoteUrl: nil,
                fileData: imageData,
                fileName: fileName,
                mimeType: mimeType
            )
            return .success
        } catch {
            return .failure(mapError(error))
        }
    }

    private func mapError(_ error: Error) -> MemoryFormUseCaseModel.CreateResult.Error {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }
        return .unknown
    }
}
