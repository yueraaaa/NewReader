import Foundation

/// Centralised app version info. Falls back to a sane string when running
/// unbundled (e.g. `swift run` from the CLI) so views never show blank
/// or `Optional(...)` strings in About panels.
public enum AppVersion {
    public static let short: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()
    public static let build: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }()
}
