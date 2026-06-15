import Foundation

/// Loads Supabase configuration and other build-time secrets.
///
/// Resolution order (first non-empty wins for each key):
/// 1. `Bundle.main.Info.plist` — populated by `scripts/package-macos.sh` at release
///    build time, when `Sources/NewReaderMac/Secrets.plist` is merged in.
/// 2. `~/Library/Application Support/NewReader/secrets.plist` — used during local
///    development (`swift run`, Xcode debug builds) so that the real secret file
///    can live outside the working tree and never be committed to git.
///
/// Both sources are gitignored. `Secrets.plist.template` ships in the repo with
/// placeholder values for new contributors.
public enum SecretsLoader {

    /// Keys read from the secrets plist.
    public enum Key: String {
        case supabaseURL = "SupabaseURL"
        case supabasePublishableKey = "SupabasePublishableKey"
        case feedbackEmail = "FeedbackEmail"
        case cloudflareTurnstileSitekey = "CloudflareTurnstileSitekey"
    }

    /// Returns the value for `key`, or `nil` if neither source provides one.
    public static func value(for key: Key) -> String? {
        // 1) Bundle (release builds, post-merge Info.plist)
        if let bundleValue = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String,
           !bundleValue.isEmpty,
           !isPlaceholder(bundleValue) {
            return bundleValue
        }

        // 2) User-level secrets plist (development)
        if let devValue = readFromUserDirectory(key: key),
           !devValue.isEmpty {
            return devValue
        }

        return nil
    }

    // MARK: - Private

    /// Detects placeholder values shipped via `Secrets.plist.template` so they
    /// don't accidentally satisfy the lookup and cause confusing runtime errors
    /// later in a different layer.
    private static func isPlaceholder(_ value: String) -> Bool {
        value.hasPrefix("YOUR_") || value.hasPrefix("https://YOUR-PROJECT")
    }

    /// Path to the user-level secrets plist. Created on demand by callers.
    public static var userSecretsURL: URL {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support")
        return support
            .appendingPathComponent("NewReader", isDirectory: true)
            .appendingPathComponent("secrets.plist")
    }

    private static func readFromUserDirectory(key: Key) -> String? {
        let url = userSecretsURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        // plistlib-style parsing: try XML first, then binary.
        let plist: [String: Any]?
        if let xml = try? PropertyListSerialization.propertyList(
            from: data, options: [], format: nil
        ) as? [String: Any] {
            plist = xml
        } else {
            plist = nil
        }
        return plist?[key.rawValue] as? String
    }
}
