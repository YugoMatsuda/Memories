import Foundation
import Domains
@preconcurrency import Shared

// MARK: - Protocol

public protocol AlbumFormUseCaseProtocol: Sendable {
    func createAlbum(title: String, coverImageData: Data?) async -> Shared.AlbumCreateResult
    func updateAlbum(album: Album, title: String, coverImageData: Data?) async -> Shared.AlbumUpdateResult
}

// MARK: - Adapter

public final class AlbumFormUseCaseAdapter: AlbumFormUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.AlbumFormUseCase

    public init(kmpUseCase: Shared.AlbumFormUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    public func createAlbum(title: String, coverImageData: Data?) async -> Shared.AlbumCreateResult {
        do {
            let imageBytes = coverImageData.map { KotlinByteArray(data: $0) }
            return try await kmpUseCase.createAlbum(title: title, coverImageData: imageBytes)
        } catch {
            return Shared.AlbumCreateResult.Failure(error: .unknown)
        }
    }

    public func updateAlbum(album: Album, title: String, coverImageData: Data?) async -> Shared.AlbumUpdateResult {
        do {
            let imageBytes = coverImageData.map { KotlinByteArray(data: $0) }
            return try await kmpUseCase.updateAlbum(album: album, title: title, coverImageData: imageBytes)
        } catch {
            return Shared.AlbumUpdateResult.Failure(error: .unknown)
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
