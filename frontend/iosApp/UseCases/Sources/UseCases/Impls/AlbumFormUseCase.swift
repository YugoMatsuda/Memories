import Foundation
import Domains
import APIGateways

public struct AlbumFormUseCase: AlbumFormUseCaseProtocol, Sendable {
    private let albumGateway: AlbumGatewayProtocol

    public init(albumGateway: AlbumGatewayProtocol) {
        self.albumGateway = albumGateway
    }

    public func createAlbum(title: String, coverImageData: Data?) async -> AlbumFormUseCaseModel.CreateResult {
        do {
            let response = try await albumGateway.createAlbum(title: title, coverImageUrl: nil)
            var album = AlbumMapper.toDomain(response)

            if let imageData = coverImageData {
                let uploadedAlbum = try await uploadCoverImage(albumId: album.id, imageData: imageData)
                album = uploadedAlbum
            }

            return .success(album)
        } catch {
            return .failure(mapError(error))
        }
    }

    public func updateAlbum(albumId: Int, title: String, coverImageData: Data?) async -> AlbumFormUseCaseModel.UpdateResult {
        do {
            let response = try await albumGateway.updateAlbum(albumId: albumId, title: title, coverImageUrl: nil)
            var album = AlbumMapper.toDomain(response)

            if let imageData = coverImageData {
                let uploadedAlbum = try await uploadCoverImage(albumId: album.id, imageData: imageData)
                album = uploadedAlbum
            }

            return .success(album)
        } catch {
            return .failure(mapUpdateError(error))
        }
    }

    private func uploadCoverImage(albumId: Int, imageData: Data) async throws -> Album {
        let fileName = "\(UUID().uuidString).jpg"
        let mimeType = "image/jpeg"
        let response = try await albumGateway.uploadCoverImage(
            albumId: albumId,
            fileData: imageData,
            fileName: fileName,
            mimeType: mimeType
        )
        return AlbumMapper.toDomain(response)
    }

    private func mapError(_ error: Error) -> AlbumFormUseCaseModel.CreateResult.Error {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }
        return .unknown
    }

    private func mapUpdateError(_ error: Error) -> AlbumFormUseCaseModel.UpdateResult.Error {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }
        return .unknown
    }
}
