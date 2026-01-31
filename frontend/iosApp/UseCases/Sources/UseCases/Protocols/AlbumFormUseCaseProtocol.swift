import Foundation
import Domains

public enum AlbumFormUseCaseModel {
    public enum CreateResult {
        case success(Album)
        case failure(Error)

        public enum Error: Equatable {
            case networkError
            case serverError
            case unknown
        }
    }

    public enum UpdateResult {
        case success(Album)
        case failure(Error)

        public enum Error: Equatable {
            case networkError
            case serverError
            case notFound
            case unknown
        }
    }
}

public protocol AlbumFormUseCaseProtocol: Sendable {
    func createAlbum(title: String, coverImageData: Data?) async -> AlbumFormUseCaseModel.CreateResult
    func updateAlbum(albumId: Int, title: String, coverImageData: Data?) async -> AlbumFormUseCaseModel.UpdateResult
}
