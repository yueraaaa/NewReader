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

    public init(article: Article, viewModel: ReaderViewModel) {
        self.article = article
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header: ViewThatFits prevents ScrollView from expanding in VStack
            ViewThatFits(in: .vertical) {
                headerContent
                    .padding(20)

                ScrollView {
                    headerContent
                        .padding(20)
                }
                .frame(maxHeight: 380)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Article body fills remaining height, WKWebView scrolls internally
            ArticleContentView(html: article.contentHTML)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    withAnimation { showVoicePanel.toggle() }
                    if showVoicePanel {
                        viewModel.ttsService.speak(article.contentHTML)
                    } else {
                        viewModel.ttsService.stop()
                    }
                } label: {
                    Image(systemName: showVoicePanel ? "speaker.wave.2.fill" : "speaker.wave.2")
                }
                .help("语音朗读")

                Button {
                    Task {
                        isExtracting = true
                        _ = await viewModel.extractFullText(article)
                        isExtracting = false
                    }
                } label: {
                    Image(systemName: isExtracting ? "doc.text.magnifyingglass" : "doc.text")
                }
                .help("提取全文")
                .disabled(isExtracting)

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

                Menu {
                    Button {
                        Task {
                            isSummarizing = true
                            aiSummary = await viewModel.summarize(article)
                            isSummarizing = false
                        }
                    } label: {
                        Label("AI 摘要", systemImage: "sparkles")
                    }
                    .disabled(isSummarizing)

                    Divider()

                    ForEach(TranslationLanguage.allCases, id: \.self) { lang in
                        Button {
                            Task {
                                isTranslating = true
                                selectedLanguage = lang
                                translatedText = await viewModel.translate(article, to: lang)
                                isTranslating = false
                            }
                        } label: {
                            Label("翻译为 \(lang.displayName)", systemImage: "globe")
                        }
                    }
                    .disabled(isTranslating)
                } label: {
                    Image(systemName: "brain.head.profile")
                }
                .help("AI 功能")

                Button {
                    viewModel.toggleStarred(article)
                } label: {
                    Image(systemName: article.isStarred ? "star.fill" : "star")
                        .foregroundStyle(article.isStarred ? .yellow : .secondary)
                }
                .help(article.isStarred ? "取消星标" : "星标")
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

    // MARK: - Header Content

    @ViewBuilder
    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(article.title)
                .font(.title2.bold())
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

            Divider()

            if let summary = aiSummary ?? article.aiSummary {
                VStack(alignment: .leading, spacing: 6) {
                    Label("AI 摘要", systemImage: "sparkles")
                        .font(.caption.bold())
                        .foregroundStyle(.purple)
                    Text(summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(12)
                .background(Color.purple.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }

            if let translation = translatedText {
                VStack(alignment: .leading, spacing: 6) {
                    Label("\(selectedLanguage.displayName) 翻译", systemImage: "globe")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                    Text(translation)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding(12)
                .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }

            if showVoicePanel {
                VoiceControlPanel(ttsService: viewModel.ttsService)
            }

            if translatedText != nil {
                Text("原文")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
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

    public init(html: String) { self.html = html }

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
        webView.loadHTMLString(wrapHTML(html), baseURL: nil)
    }
}

#else
import WebKit

public struct ArticleContentView: UIViewRepresentable {
    let html: String

    public init(html: String) { self.html = html }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = false
        config.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrapHTML(html), baseURL: nil)
    }
}
#endif

// MARK: - HTML Wrapper

public func wrapHTML(_ html: String) -> String {
    """
    <!DOCTYPE html><html><head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: http: data:; style-src 'unsafe-inline'; font-src 'none'; frame-src 'none'; media-src https: http:;">
    <style>
      :root { color-scheme: light dark; }
      body { font-family: -apple-system, BlinkMacSystemFont, sans-serif;
             font-size: 16px; line-height: 1.7; color: #333;
             padding: 20px 24px; margin: 0 auto; max-width: 740px; word-wrap: break-word; overflow-wrap: break-word; }
      @media (prefers-color-scheme: dark) {
        body { color: #ddd; background: transparent; } a { color: #6ea8fe; }
      }
      img, video, iframe { max-width: 100%; height: auto; }
      pre { overflow-x: auto; padding: 12px; background: #f5f5f5; border-radius: 6px; }
    </style></head><body>\(html)</body></html>
    """
}
