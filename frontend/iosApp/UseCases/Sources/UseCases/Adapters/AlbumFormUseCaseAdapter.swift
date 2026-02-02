import Foundation
import Domains
@preconcurrency import Shared

/// Adapter that wraps KMP AlbumFormUseCase to conform to Swift AlbumFormUseCaseProtocol
public final class AlbumFormUseCaseAdapter: AlbumFormUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.AlbumFormUseCase

    public init(kmpUseCase: Shared.AlbumFormUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func createAlbum(title: String, coverImageData: Data?) async -> AlbumFormUseCaseModel.CreateResult {
        do {
            let imageBytes = coverImageData.map { KotlinByteArray(data: $0) }
            let result = try await kmpUseCase.createAlbum(title: title, coverImageData: imageBytes)

            if let success = result as? Shared.AlbumCreateResult.Success {
                return .success(success.album)
            } else if let pendingSync = result as? Shared.AlbumCreateResult.SuccessPendingSync {
                return .successPendingSync(pendingSync.album)
            } else if let failure = result as? Shared.AlbumCreateResult.Failure {
                return .failure(mapCreateError(failure.error))
            }
            return .failure(.unknown)
        } catch {
            return .failure(.unknown)
        }
    }

    public func updateAlbum(album: Album, title: String, coverImageData: Data?) async -> AlbumFormUseCaseModel.UpdateResult {
        do {
            let imageBytes = coverImageData.map { KotlinByteArray(data: $0) }
            let result = try await kmpUseCase.updateAlbum(album: album, title: title, coverImageData: imageBytes)

            if let success = result as? Shared.AlbumUpdateResult.Success {
                return .success(success.album)
            } else if let pendingSync = result as? Shared.AlbumUpdateResult.SuccessPendingSync {
                return .successPendingSync(pendingSync.album)
            } else if let failure = result as? Shared.AlbumUpdateResult.Failure {
                return .failure(mapUpdateError(failure.error))
            }
            return .failure(.unknown)
        } catch {
            return .failure(.unknown)
        }
    }

    private func mapCreateError(_ error: Shared.AlbumCreateError) -> AlbumFormUseCaseModel.CreateResult.Error {
        switch error {
        case .networkError: return .networkError
        case .serverError: return .serverError
        case .imageStorageFailed: return .imageStorageFailed
        case .databaseError: return .databaseError
        default: return .unknown
        }
    }

    private func mapUpdateError(_ error: Shared.AlbumUpdateError) -> AlbumFormUseCaseModel.UpdateResult.Error {
        switch error {
        case .networkError: return .networkError
        case .serverError: return .serverError
        case .notFound: return .notFound
        case .imageStorageFailed: return .imageStorageFailed
        case .databaseError: return .databaseError
        default: return .unknown
        }
    }
}

// MARK: - KotlinByteArray Extension

extension KotlinByteArray {
    convenience init(data: Data) {
        let bytes = [UInt8](data)
        self.init(size: Int32(bytes.count))
        for (index, byte) in bytes.enumerated() {
            self.set(index: Int32(index), value: Int8(bitPattern: byte))
        }
    }
}
