import Foundation

/// Resolves relative image URLs to absolute URLs using the configured base URL.
/// Configure at app startup before using domain models.
public enum ImageURLResolver {
    /// Base URL for resolving relative paths. Set once at app startup.
    nonisolated(unsafe) public static var baseURL: URL?

    /// Resolves a URL string to a full URL.
    /// - Parameter urlString: The URL string (can be relative like "/uploads/image.jpg" or absolute)
    /// - Returns: The resolved URL, or nil if invalid
    public static func resolve(_ urlString: String?) -> URL? {
        guard let urlString, !urlString.isEmpty else { return nil }

        // If it's a relative path starting with "/"
        if urlString.hasPrefix("/") {
            guard let base = baseURL else {
                // Fallback: try to construct URL as-is (will fail for relative paths)
                return URL(string: urlString)
            }
            // Construct absolute URL from base + relative path
            return URL(string: urlString, relativeTo: base)?.absoluteURL
        }

        // If it's already an absolute URL or a file path
        return URL(string: urlString)
    }

    /// Resolves a URL string to a file URL for local paths.
    /// - Parameter path: The local file path
    /// - Returns: File URL for the path
    public static func resolveLocalPath(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }
}
