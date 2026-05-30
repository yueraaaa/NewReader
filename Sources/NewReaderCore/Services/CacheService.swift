import Foundation

/// Manages offline caching of article content and images
public final class CacheService {
    private let cacheDirectory: URL
    private let imageCache: URLCache

    public init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("NewReader/ArticleCache")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // 50MB memory, 200MB disk for images
        imageCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "NewReader/ImageCache"
        )
    }

    /// Cache article HTML content for offline reading
    public func cacheArticle(id: UUID, html: String, title: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(id.uuidString).html")
        let wrapped = """
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <title>\(escapeHTML(title))</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: http: data:; style-src 'unsafe-inline'; font-src 'none'; frame-src 'none'; media-src https: http:;">
        <style>
          :root { color-scheme: light dark; }
          body { font-family: -apple-system, sans-serif; font-size: 16px;
                 line-height: 1.7; padding: 16px; max-width: 720px; margin: 0 auto;
                 color: #333; }
          @media (prefers-color-scheme: dark) { body { color: #ddd; background: #1c1c1e; } }
          img, video { max-width: 100%; height: auto; }
        </style></head><body>\(HTMLSanitizer.sanitize(html))</body></html>
        """
        try? wrapped.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Load cached article if available
    public func loadCachedArticle(id: UUID) -> String? {
        let fileURL = cacheDirectory.appendingPathComponent("\(id.uuidString).html")
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    /// Check if article is cached
    public func isCached(id: UUID) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(id.uuidString).html")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Remove cached article
    public func removeCache(id: UUID) {
        let fileURL = cacheDirectory.appendingPathComponent("\(id.uuidString).html")
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Clear all cached articles
    public func clearAllCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Total cache size in bytes
    public func cacheSize() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        return files.reduce(0) { acc, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return acc + Int64(size)
        }
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
