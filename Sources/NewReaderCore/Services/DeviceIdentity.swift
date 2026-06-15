import Foundation

/// Stable per-device identifier persisted in the Keychain.
///
/// The Edge Function uses this as the rate-limit key (see
/// `supabase/migrations/003_device_quota.sql`). A user switching devices
/// gets a fresh quota — that's accepted behavior; the goal is to slow
/// down a single physical host from hammering the AI proxy with many
/// throwaway Supabase auth accounts, not to track the same human
/// across hardware.
public enum DeviceIdentity {

    /// Keychain account name. Distinct from the API-key namespace
    /// (`com.newreader.apikeys`) so secret rotation doesn't invalidate it.
    private static let keychainKey = "newreader.device_id"

    /// Lazily resolved on first access. Subsequent reads are O(1).
    public static let id: String = {
        if let existing = KeychainHelper.load(key: keychainKey),
           !existing.isEmpty {
            return existing
        }
        let new = UUID().uuidString
        _ = KeychainHelper.save(key: keychainKey, value: new)
        return new
    }()
}
