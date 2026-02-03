import Foundation

public enum ImageURLResolver {
    /// Base URL for resolving relative paths. Set once at app startup.
    nonisolated(unsafe) public static var baseURL: URL?

    public static func resolve(_ urlString: String?) -> URL? {
        guard let urlString, !urlString.isEmpty else { return nil }

        // If it's a relative path starting with "/"
        if urlString.hasPrefix("/") {
            guard let base = baseURL else {
                // Fallback
                return URL(string: urlString)
            }
            return URL(string: urlString, relativeTo: base)?.absoluteURL
        }

        return URL(string: urlString)
    }

    public static func resolveLocalPath(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }
}
