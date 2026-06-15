import SwiftUI
import WebKit

#if os(macOS)
typealias TurnstilePlatformView = TurnstileNSView
#else
typealias TurnstilePlatformView = TurnstileUIView
#endif

/// Renders a Cloudflare Turnstile invisible widget in a `WKWebView` and
/// returns a one-shot captcha token via `TurnstileChallenge.fetchToken()`.
///
/// Cloudflare's invisible mode is intended to never require user
/// interaction, but in practice may show a challenge for suspicious
/// traffic. In either case the resulting token is a one-time
/// `cf-turnstile-response` opaque string the Edge Function verifies
/// server-side.
public enum TurnstileChallenge {

    /// Cloudflare's documented "always passes" development sitekey.
    /// Lets local dev run without registering a real widget.
    public static let developmentSitekey = "1x00000000000000000000AA"

    /// Returns the configured sitekey: production value from
    /// `SecretsLoader` (or `Secrets.plist`), falling back to Cloudflare's
    /// development sitekey for local builds.
    public static var sitekey: String {
        SecretsLoader.value(for: .cloudflareTurnstileSitekey) ?? developmentSitekey
    }

    /// Renders the widget off-screen and resolves with the resulting token.
    /// Times out after `timeout` seconds; rejects on validation error.
    public static func fetchToken(timeout: TimeInterval = 30) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let host = TurnstileHost(sitekey: sitekey, timeout: timeout) { result in
                switch result {
                case .success(let token): continuation.resume(returning: token)
                case .failure(let error):  continuation.resume(throwing: error)
                }
            }
            host.start()
        }
    }
}

// MARK: - Host

/// Owns a `WKWebView`, loads the Turnstile JS API, renders the widget,
/// and returns the token via the `completion` closure exactly once.
final class TurnstileHost: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

    enum TurnstileError: LocalizedError {
        case loadFailed(String)
        case timeout
        case widgetError(String)

        var errorDescription: String? {
            switch self {
            case .loadFailed(let m): return "Turnstile 加载失败: \(m)"
            case .timeout:           return "Turnstile 验证超时"
            case .widgetError(let m):return "Turnstile 错误: \(m)"
            }
        }
    }

    private let sitekey: String
    private let timeout: TimeInterval
    private let completion: (Result<String, Error>) -> Void
    private var webView: WKWebView?
    private var hasCompleted = false
    private var timeoutWork: DispatchWorkItem?

    init(sitekey: String, timeout: TimeInterval, completion: @escaping (Result<String, Error>) -> Void) {
        self.sitekey = sitekey
        self.timeout = timeout
        self.completion = completion
    }

    func start() {
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()
        userContent.add(self, name: "turnstile")
        config.userContentController = userContent
        // Turnstile JS lives on challenges.cloudflare.com. For iOS we
        // can't enable `limitsNavigationsToAppBoundDomains` here, so
        // this WKWebView is allowed to talk to the public internet.
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 80),
                                configuration: config)
        webView.navigationDelegate = self
        webView.isHidden = true
        self.webView = webView
        loadWidget()
    }

    private func loadWidget() {
        let html = """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8">
        <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onTurnstileLoad&render=explicit" async defer></script>
        <style>body{margin:0;background:transparent;}</style>
        </head><body>
        <div id="widget"></div>
        <script>
          window.onTurnstileLoad = function() {
            if (!window.turnstile) { return; }
            window.turnstile.render('#widget', {
              sitekey: '\(sitekey)',
              callback: function(token) {
                window.webkit.messageHandlers.turnstile.postMessage({ok: true, token: token});
              },
              'error-callback': function(err) {
                window.webkit.messageHandlers.turnstile.postMessage({ok: false, err: String(err)});
              },
              'expired-callback': function() {
                window.webkit.messageHandlers.turnstile.postMessage({ok: false, err: 'expired'});
              }
            });
          };
        </script>
        </body></html>
        """
        scheduleTimeout()
        webView?.loadHTMLString(html, baseURL: URL(string: "https://newreader.local"))
    }

    private func scheduleTimeout() {
        let work = DispatchWorkItem { [weak self] in
            self?.finish(.failure(TurnstileError.timeout))
        }
        timeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: work)
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Page load complete; widget will render itself once api.js loads.
        // Timeout is the only deadline.
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(.failure(TurnstileError.loadFailed(error.localizedDescription)))
    }

    // MARK: WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "turnstile" else { return }
        let body = message.body as? [String: Any] ?? [:]
        if let ok = body["ok"] as? Bool, ok, let token = body["token"] as? String {
            finish(.success(token))
        } else {
            let err = body["err"] as? String ?? "unknown"
            finish(.failure(TurnstileError.widgetError(err)))
        }
    }

    private func finish(_ result: Result<String, Error>) {
        guard !hasCompleted else { return }
        hasCompleted = true
        timeoutWork?.cancel()
        completion(result)
    }
}

// MARK: - Platform SwiftUI wrapper

#if os(macOS)

/// macOS: wrap a hidden `NSViewRepresentable` so the WKWebView exists
/// for the lifetime of the SwiftUI view. The challenge is started by
/// `TurnstileChallenge.fetchToken()` which builds a fresh view each
/// call, so this wrapper isn't directly used by the login flow but
/// kept for any future inline rendering.
struct TurnstileNSView: NSViewRepresentable {
    let sitekey: String
    func makeNSView(context: Context) -> NSView {
        let v = NSView(frame: .zero)
        v.isHidden = true
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

#else

struct TurnstileUIView: UIViewRepresentable {
    let sitekey: String
    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        v.isHidden = true
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#endif
