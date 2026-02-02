import Foundation

public enum DeepLink: Equatable, Sendable {
    case album(albumId: Int)

    public static func parse(url: URL) -> DeepLink? {
        guard url.scheme == "myapp",
              url.host == "albums",
              let albumIdString = url.pathComponents.dropFirst().first,
              let albumId = Int(albumIdString) else {
            return nil
        }
        return .album(albumId: albumId)
    }
}
