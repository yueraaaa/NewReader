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
    @State private var webViewHeight: CGFloat = 500

    public init(article: Article, viewModel: ReaderViewModel) {
        self.article = article
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(article.title)
                    .font(.title2.bold())
                    .textSelection(.enabled)

                // Metadata
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

                // AI Summary
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

                // Translated content
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

                // Voice control panel
                if showVoicePanel {
                    VoiceControlPanel(ttsService: viewModel.ttsService)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Article content
                VStack(alignment: .leading, spacing: 8) {
                    if translatedText != nil {
                        Text("原文")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    ArticleContentView(html: article.contentHTML, dynamicHeight: $webViewHeight)
                        .frame(height: webViewHeight)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItemGroup {
                // Voice toggle
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

                // Full-text extraction
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

                // Cache
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

                // AI tools
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

                // Star
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
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
    }
}

/// Compact voice control panel
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

            Image(systemName: "tortoise")
                .font(.system(size: 10))
            Slider(value: $rate, in: 0...1) { _ in
                ttsService.setRate(Float(rate))
            }
            .frame(width: 80)
            Image(systemName: "hare")
                .font(.system(size: 10))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#if os(macOS)
import WebKit

public struct ArticleContentView: NSViewRepresentable {
    let html: String
    @Binding var dynamicHeight: CGFloat

    public init(html: String, dynamicHeight: Binding<CGFloat> = .constant(500)) {
        self.html = html
        self._dynamicHeight = dynamicHeight
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(dynamicHeight: $dynamicHeight)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = false
        config.defaultWebpagePreferences = prefs
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        let webView = context.coordinator.webView
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrapHTML(html), baseURL: nil)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {
        let webView: WKWebView
        private var heightBinding: Binding<CGFloat>
        private var observation: NSKeyValueObservation?

        init(dynamicHeight: Binding<CGFloat>) {
            self.heightBinding = dynamicHeight
            let config = WKWebViewConfiguration()
            let prefs = WKWebpagePreferences()
            prefs.allowsContentJavaScript = false
            config.defaultWebpagePreferences = prefs
            self.webView = WKWebView(frame: .zero, configuration: config)
            super.init()
            webView.navigationDelegate = self
            observation = webView.scrollView.observe(\.documentView?.frame) { [weak self] _, _ in
                self?.updateHeight()
            }
        }

        private func updateHeight() {
            guard let docView = webView.scrollView.documentView else { return }
            let h = docView.frame.height
            if h > 50 {
                DispatchQueue.main.async { self.heightBinding.wrappedValue = h }
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateHeight()
        }
    }
}
#else
import WebKit

public struct ArticleContentView: UIViewRepresentable {
    let html: String
    @Binding var dynamicHeight: CGFloat

    public init(html: String, dynamicHeight: Binding<CGFloat> = .constant(500)) {
        self.html = html
        self._dynamicHeight = dynamicHeight
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(dynamicHeight: $dynamicHeight)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = context.coordinator.webView
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrapHTML(html), baseURL: nil)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {
        let webView: WKWebView
        private var heightBinding: Binding<CGFloat>
        private var observation: NSKeyValueObservation?

        init(dynamicHeight: Binding<CGFloat>) {
            self.heightBinding = dynamicHeight
            let config = WKWebViewConfiguration()
            let prefs = WKWebpagePreferences()
            prefs.allowsContentJavaScript = false
            config.defaultWebpagePreferences = prefs
            self.webView = WKWebView(frame: .zero, configuration: config)
            super.init()
            webView.navigationDelegate = self
            observation = webView.scrollView.observe(\.contentSize) { [weak self] _, _ in
                self?.updateHeight()
            }
        }

        private func updateHeight() {
            let h = webView.scrollView.contentSize.height
            if h > 50 {
                DispatchQueue.main.async { self.heightBinding.wrappedValue = h }
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateHeight()
        }
    }
}
#endif

public func wrapHTML(_ html: String) -> String {
    """
    <!DOCTYPE html><html><head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: http: data:; style-src 'unsafe-inline'; font-src 'none'; frame-src 'none'; media-src https: http:;">
    <style>
      :root { color-scheme: light dark; }
      body { font-family: -apple-system, BlinkMacSystemFont, sans-serif;
             font-size: 16px; line-height: 1.7; color: #333;
             padding: 0; margin: 0; max-width: 100%; }
      @media (prefers-color-scheme: dark) {
        body { color: #ddd; background: transparent; } a { color: #6ea8fe; }
      }
      img, video, iframe { max-width: 100%; height: auto; }
      pre { overflow-x: auto; padding: 12px; background: #f5f5f5; border-radius: 6px; }
    </style></head><body>\(html)</body></html>
    """
}
