import Foundation
import Domains
@preconcurrency import Shared

/// Adapter that wraps KMP MemoryFormUseCase to conform to Swift MemoryFormUseCaseProtocol
public final class MemoryFormUseCaseAdapter: MemoryFormUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.MemoryFormUseCase

    public init(kmpUseCase: Shared.MemoryFormUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func createMemory(album: Album, title: String, imageData: Data) async -> MemoryFormUseCaseModel.CreateResult {
        do {
            let imageBytes = KotlinByteArray(data: imageData)
            let result = try await kmpUseCase.createMemory(album: album, title: title, imageData: imageBytes)

            if let success = result as? Shared.MemoryCreateResult.Success {
                return .success(success.memory)
            } else if let pendingSync = result as? Shared.MemoryCreateResult.SuccessPendingSync {
                return .successPendingSync(pendingSync.memory)
            } else if let failure = result as? Shared.MemoryCreateResult.Failure {
                return .failure(mapError(failure.error))
            }
            return .failure(.unknown)
        } catch {
            return .failure(.unknown)
        }
    }

    private func mapError(_ error: Shared.MemoryCreateError) -> MemoryFormUseCaseModel.CreateResult.Error {
        switch error {
        case .networkError: return .networkError
        case .imageStorageFailed: return .imageStorageFailed
        case .databaseError: return .databaseError
        default: return .unknown
        }
    }
}
