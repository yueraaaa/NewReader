import SwiftUI

/// Full article reading view with AI tools, TTS, and full-text extraction
public struct ArticleReaderView: View {
    public let article: Article
    @ObservedObject var viewModel: ReaderViewModel

    @State private var aiSummary: String?
    @State private var translatedText: String?
    @State private var selectedLanguage: TranslationLanguage = .zh
    @State private var isSummarizing: Bool = false
    @State private var isTranslating: Bool = false
    @State private var isExtracting: Bool = false
    @State private var showVoicePanel: Bool = false

    /// ID of the article the in-flight AI/extract task belongs to. Results from
    /// tasks that don't match the currently shown article are dropped, so
    /// switching articles mid-request never paints stale data on the new one.
    @State private var activeTaskArticleID: UUID?
    @State private var fontSize: CGFloat = 16

    public init(article: Article, viewModel: ReaderViewModel) {
        self.article = article
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Title + metadata in native SwiftUI (always visible, never scrolls separately)
            titleBar
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            .frame(maxWidth: .infinity)

            Divider()

            // AI summary + translation + article body in one scrollable WKWebView
            ArticleContentView(
                html: article.contentHTML,
                baseURL: article.url,
                fontSize: fontSize,
                summary: aiSummary ?? article.aiSummary,
                translation: translatedText,
                translationLanguage: translatedText != nil ? selectedLanguage.displayName : nil
            )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: article.id) { _, _ in
            if !article.isRead { viewModel.toggleRead(article) }
            aiSummary = nil
            translatedText = nil
            showVoicePanel = false
            isSummarizing = false
            isTranslating = false
            isExtracting = false
            activeTaskArticleID = article.id
            viewModel.ttsService.stop()
        }
        .toolbar {
            ToolbarItemGroup {
                // AI 摘要 — direct button
                Button {
                    Task {
                        let taskID = article.id
                        activeTaskArticleID = taskID
                        isSummarizing = true
                        let result = await viewModel.summarize(article)
                        if activeTaskArticleID == taskID {
                            aiSummary = result
                            isSummarizing = false
                        }
                    }
                } label: {
                    Image(systemName: isSummarizing ? "sparkles" : "sparkle")
                }
                .disabled(isSummarizing)
                .help("AI 摘要")

                // 翻译 — one-click translate to preferred language
                Button {
                    Task {
                        let taskID = article.id
                        activeTaskArticleID = taskID
                        isTranslating = true
                        let lang = TranslationLanguage.preferred
                        selectedLanguage = lang
                        let result = await viewModel.translate(article, to: lang)
                        if activeTaskArticleID == taskID {
                            translatedText = result
                            isTranslating = false
                        }
                    }
                } label: {
                    Image(systemName: isTranslating ? "globe.americas.fill" : "globe")
                }
                .disabled(isTranslating)
                .help("翻译为\(TranslationLanguage.preferred.displayName)")

                // 提取全文
                Button {
                    Task {
                        let taskID = article.id
                        activeTaskArticleID = taskID
                        isExtracting = true
                        _ = await viewModel.extractFullText(article)
                        if activeTaskArticleID == taskID {
                            isExtracting = false
                        }
                    }
                } label: {
                    Image(systemName: isExtracting ? "doc.text.magnifyingglass" : "doc.text")
                }
                .disabled(isExtracting)
                .help("提取全文")

                // TTS 语音朗读 — 三态：播放 → 暂停 → 继续
                let isActive = viewModel.ttsService.isSpeaking && !viewModel.ttsService.isPaused
                let isPaused = viewModel.ttsService.isPaused
                Button {
                    if isActive {
                        viewModel.ttsService.pause()
                    } else if isPaused {
                        viewModel.ttsService.resume()
                    } else {
                        withAnimation { showVoicePanel = true }
                        viewModel.ttsService.speak(article.contentHTML)
                    }
                } label: {
                    Image(systemName: isActive ? "speaker.wave.2.fill"
                                   : isPaused ? "play.fill"
                                   : "speaker.wave.2")
                }
                .help(isActive ? "暂停朗读" : isPaused ? "继续朗读" : "语音朗读")

                // 缓存
                Button {
                    if viewModel.isArticleCached(article) {
                        viewModel.cacheService.removeCache(id: article.id)
                    } else {
                        viewModel.cacheArticle(article)
                    }
                } label: {
                    Image(systemName: viewModel.isArticleCached(article) ? "arrow.down.circle.fill" : "arrow.down.circle")
                }
                .help(viewModel.isArticleCached(article) ? "已缓存" : "缓存离线阅读")

                // 星标
                Button {
                    viewModel.toggleStarred(article)
                } label: {
                    Image(systemName: article.isStarred ? "star.fill" : "star")
                        .foregroundStyle(article.isStarred ? .yellow : .secondary)
                }
                .help(article.isStarred ? "取消星标" : "星标")

                // Font size
                Button {
                    let sizes: [CGFloat] = [14, 16, 18, 20, 22]
                    if let i = sizes.firstIndex(of: fontSize) {
                        fontSize = sizes[(i + 1) % sizes.count]
                    }
                } label: {
                    Image(systemName: "textformat.size")
                }
                .help("字号: \(Int(fontSize))pt")
            }
        }
        .overlay {
            if isSummarizing || isTranslating || isExtracting {
                ZStack {
                    Color.black.opacity(0.1)
                    ProgressView().scaleEffect(0.8)
                }
            }
        }
    }



    // MARK: - Title Bar

    @ViewBuilder
    private var titleBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.title)
                .font(.title3.bold())
                .lineLimit(2)
                .textSelection(.enabled)

            HStack(spacing: 12) {
                if let author = article.author {
                    Label(author, systemImage: "person")
                }
                if let date = article.publishedDate {
                    Label(date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                }
                Label(article.feed?.title ?? "", systemImage: "dot.radiowaves.left.and.right")
                if viewModel.isArticleCached(article) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                        .help("已缓存")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}





// MARK: - Voice Control Panel

struct VoiceControlPanel: View {
    @ObservedObject var ttsService: TTSService
    @State private var rate: Double = 0.5

    var body: some View {
        HStack(spacing: 12) {
            Button {
                ttsService.isPaused ? ttsService.resume() : ttsService.pause()
            } label: {
                Image(systemName: ttsService.isPaused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(.borderless)

            Button {
                ttsService.stop()
            } label: {
                Image(systemName: "stop.fill")
            }
            .buttonStyle(.borderless)

            Divider().frame(height: 16)

            Image(systemName: "tortoise").font(.system(size: 10))
            Slider(value: $rate, in: 0...1) { _ in
                ttsService.setRate(Float(rate))
            }
            .frame(width: 80)
            Image(systemName: "hare").font(.system(size: 10))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Article Content (WKWebView)

#if os(macOS)
import WebKit

public struct ArticleContentView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    let fontSize: CGFloat
    let summary: String?
    let translation: String?
    let translationLanguage: String?

    public init(
        html: String,
        baseURL: String? = nil,
        fontSize: CGFloat = 16,
        summary: String? = nil,
        translation: String? = nil,
        translationLanguage: String? = nil
    ) {
        self.html = html
        // Validate via URLValidator so an attacker-controlled feed URL can't
        // smuggle in a private/loopback baseURL into WKWebView. Falls back to
        // nil (no relative-URL resolution) on rejection.
        self.baseURL = baseURL.flatMap { URLValidator.validate($0) }
        self.fontSize = fontSize
        self.summary = summary
        self.translation = translation
        self.translationLanguage = translationLanguage
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = false
        config.defaultWebpagePreferences = prefs
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrapHTMLWithExtras(html, fontSize: fontSize, summary: summary, translation: translation, translationLanguage: translationLanguage), baseURL: baseURL)
    }
}

#else
import WebKit

public struct ArticleContentView: UIViewRepresentable {
    let html: String
    let baseURL: URL?
    let fontSize: CGFloat
    let summary: String?
    let translation: String?
    let translationLanguage: String?

    public init(
        html: String,
        baseURL: String? = nil,
        fontSize: CGFloat = 16,
        summary: String? = nil,
        translation: String? = nil,
        translationLanguage: String? = nil
    ) {
        self.html = html
        // Validate via URLValidator so an attacker-controlled feed URL can't
        // smuggle in a private/loopback baseURL into WKWebView. Falls back to
        // nil (no relative-URL resolution) on rejection.
        self.baseURL = baseURL.flatMap { URLValidator.validate($0) }
        self.fontSize = fontSize
        self.summary = summary
        self.translation = translation
        self.translationLanguage = translationLanguage
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = false
        config.defaultWebpagePreferences = prefs
        if #available(iOS 14.0, *) {
            config.limitsNavigationsToAppBoundDomains = true
        }
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrapHTMLWithExtras(html, fontSize: fontSize, summary: summary, translation: translation, translationLanguage: translationLanguage), baseURL: baseURL)
    }
}
#endif

// MARK: - HTML Wrapper

public func wrapHTML(_ html: String, fontSize: CGFloat = 16) -> String {
    """
    <!DOCTYPE html><html><head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: http: data:; style-src 'unsafe-inline'; font-src 'none'; frame-src 'none'; media-src https: http:;">
    <style>
      :root { color-scheme: light dark; }
      body { font-family: -apple-system, BlinkMacSystemFont, sans-serif;
             font-size: \(Int(fontSize))px; line-height: 1.7; color: #333;
             padding: 20px 24px; margin: 0 auto; max-width: 740px; word-wrap: break-word; overflow-wrap: break-word; }
      @media (prefers-color-scheme: dark) {
        body { color: #ddd; background: transparent; } a { color: #6ea8fe; }
      }
      img, video, iframe { max-width: 100%; height: auto; }
      pre { overflow-x: auto; padding: 12px; background: #f5f5f5; border-radius: 6px; }
      .ai-summary { margin: 8px 0 20px 0; padding: 14px 16px; background: #f3e8ff; border-radius: 8px; border-left: 3px solid #a855f7; }
      .ai-summary .label { font-size: 11px; font-weight: 700; color: #9333ea; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; }
      .ai-summary .text { font-size: 14px; color: #555; line-height: 1.6; }
      .ai-translation { margin: 8px 0 20px 0; padding: 14px 16px; background: #eff6ff; border-radius: 8px; border-left: 3px solid #3b82f6; }
      .ai-translation .label { font-size: 11px; font-weight: 700; color: #2563eb; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; }
      .ai-translation .text { font-size: 15px; color: #333; line-height: 1.7; }
      .original-label { font-size: 12px; font-weight: 700; color: #999; margin: 24px 0 8px 0; padding-top: 16px; border-top: 1px solid #e5e5e5; }
      @media (prefers-color-scheme: dark) {
        .ai-summary { background: #2d1f3d; border-left-color: #a855f7; }
        .ai-summary .label { color: #c084fc; }
        .ai-summary .text { color: #bbb; }
        .ai-translation { background: #1e2a3d; border-left-color: #3b82f6; }
        .ai-translation .label { color: #60a5fa; }
        .ai-translation .text { color: #ccc; }
        .original-label { border-top-color: #444; color: #777; }
      }
    </style></head><body>\(html)</body></html>
    """
}

/// Wrap HTML content with injected metadata, AI summary, and translation at the top
public func wrapHTMLWithExtras(
    _ html: String,
    fontSize: CGFloat = 16,
    summary: String? = nil,
    translation: String? = nil,
    translationLanguage: String? = nil
) -> String {
    var extras = ""
    
    // AI Summary
    if let summary = summary, !summary.isEmpty {
        let escaped = summary
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
        extras += "<div class=\"ai-summary\"><div class=\"label\">✨ AI 摘要</div><div class=\"text\">\(escaped)</div></div>\n"
    }
    
    // Translation
    if let translation = translation, !translation.isEmpty {
        let langLabel = translationLanguage.map { "\($0) 翻译" } ?? "翻译"
        let escaped = translation
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
        extras += "<div class=\"ai-translation\"><div class=\"label\">🌐 \(langLabel)</div><div class=\"text\">\(escaped)</div></div>\n"
    }
    
    if !extras.isEmpty {
        extras += "<div class=\"original-label\">原文</div>\n"
    }
    
    let wrapped = wrapHTML(extras + html, fontSize: fontSize)
    return wrapped
}
