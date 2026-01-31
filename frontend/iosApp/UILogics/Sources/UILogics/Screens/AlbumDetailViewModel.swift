import Foundation
import Domains

@MainActor
public final class AlbumDetailViewModel: ObservableObject {
    public let album: Album

    public init(album: Album) {
        self.album = album
    }
}
