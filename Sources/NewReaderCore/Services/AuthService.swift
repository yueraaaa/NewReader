import Foundation
import Supabase

/// Manages Supabase authentication and provides JWT for API calls.
@MainActor
public final class AuthService: ObservableObject {
    @Published public var session: Session?
    @Published public var isLoggedIn: Bool = false
    @Published public var isInitializing: Bool = true

    private let client: SupabaseClient

    public init() {
        let url = SupabaseConfig.url
        let key = SupabaseConfig.publishableKey
        self.client = SupabaseClient(
            supabaseURL: URL(string: url)!,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: SupabaseConfig.redirectURL
                )
            )
        )

        Task {
            await restoreSession()
            isInitializing = false
        }
    }

    /// Sign up with email + password. Sends confirmation email with deep link.
    public func signUp(email: String, password: String) async throws {
        let result = try await client.auth.signUp(email: email, password: password)
        session = result.session
        isLoggedIn = session != nil
    }

    /// Sign in with email + password
    public func signIn(email: String, password: String) async throws {
        session = try await client.auth.signIn(email: email, password: password)
        isLoggedIn = true
    }

    /// Sign in with Apple
    public func signInWithApple(idToken: String, nonce: String) async throws {
        let result = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        session = result
        isLoggedIn = true
    }

    /// Sign out
    public func signOut() async throws {
        try await client.auth.signOut()
        session = nil
        isLoggedIn = false
    }

    /// Current JWT access token, nil if not logged in.
    public var accessToken: String? {
        session?.accessToken
    }

    /// Handle Supabase auth callback URL (magic link / confirmation).
    public func handleCallback(url: URL) async throws {
        try await client.auth.session(from: url)
        await restoreSession()
    }

    /// Restore session from stored credentials
    private func restoreSession() async {
        do {
            session = try await client.auth.session
            isLoggedIn = true
        } catch {
            session = nil
            isLoggedIn = false
        }
    }
}

/// Supabase project configuration — reads secrets from Secrets.plist in the app bundle.
public enum SupabaseConfig {
    public static var url: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String else {
            fatalError("Missing SupabaseURL in Info.plist — check Secrets.plist merge")
        }
        return url
    }
    public static var publishableKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SupabasePublishableKey") as? String else {
            fatalError("Missing SupabasePublishableKey in Info.plist — check Secrets.plist merge")
        }
        return key
    }
    /// Deep link redirect URL — must match the Supabase dashboard's Redirect URLs.
    public static let redirectURL = URL(string: "newreader://auth-callback")!
    /// Edge Function names
    public static let aiProxyFunction = "ai-proxy"
}
