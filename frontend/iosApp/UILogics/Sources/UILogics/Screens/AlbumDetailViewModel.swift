import Foundation
import Domains

@MainActor
public final class AlbumDetailViewModel: ObservableObject {
    public let album: Album
    private let router: AuthenticatedRouterProtocol

    public init(album: Album, router: AuthenticatedRouterProtocol) {
        self.album = album
        self.router = router
    }

    public func showEditAlbumForm() {
        router.showSheet(.albumForm(.edit(album)))
    }
}
