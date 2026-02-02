import Foundation
import Domains
@preconcurrency import Shared

// MARK: - Protocol

public protocol MemoryFormUseCaseProtocol: Sendable {
    func createMemory(album: Album, title: String, imageData: Data) async -> Shared.MemoryCreateResult
}

// MARK: - Adapter

public final class MemoryFormUseCaseAdapter: MemoryFormUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.MemoryFormUseCase

    public init(kmpUseCase: Shared.MemoryFormUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func createMemory(album: Album, title: String, imageData: Data) async -> Shared.MemoryCreateResult {
        do {
            let imageBytes = KotlinByteArray(data: imageData)
            return try await kmpUseCase.createMemory(album: album, title: title, imageData: imageBytes)
        } catch {
            return Shared.MemoryCreateResult.Failure(error: .unknown)
        }
    }
}
