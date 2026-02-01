import Foundation
import Domains

public enum AlbumFormUseCaseModel {
    public enum CreateResult {
        case success(Album)
        case successPendingSync(Album)
        case failure(Error)

        public enum Error: Equatable {
            case networkError
            case serverError
            case imageStorageFailed
            case databaseError
            case unknown
        }
    }

    public enum UpdateResult {
        case success(Album)
        case successPendingSync(Album)
        case failure(Error)

        public enum Error: Equatable {
            case networkError
            case serverError
            case notFound
            case imageStorageFailed
            case databaseError
            case unknown
        }
    }
}

public protocol AlbumFormUseCaseProtocol: Sendable {
    func createAlbum(title: String, coverImageData: Data?) async -> AlbumFormUseCaseModel.CreateResult
    func updateAlbum(album: Album, title: String, coverImageData: Data?) async -> AlbumFormUseCaseModel.UpdateResult
}
