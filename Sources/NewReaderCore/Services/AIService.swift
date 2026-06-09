import Foundation

/// Language codes supported for translation
public enum TranslationLanguage: String, CaseIterable {
    case zh = "zh"
    case en = "en"
    case ja = "ja"
    case ko = "ko"

    public var displayName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
        case .ja: return "日本語"
        case .ko: return "한국어"
        }
    }

    /// User's preferred target language for one-click translation.
    /// Stored in UserDefaults; defaults to Chinese.
    public static var preferred: TranslationLanguage {
        get {
            if let raw = UserDefaults.standard.string(forKey: "newreader_translation_language"),
               let lang = TranslationLanguage(rawValue: raw) {
                return lang
            }
            return .zh
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "newreader_translation_language")
        }
    }
}

public enum AIServiceError: LocalizedError {
    case notLoggedIn
    case requestFailed
    case invalidResponse
    case noContent
    case dailyLimitReached
    case paymentRequired

    public var errorDescription: String? {
        switch self {
        case .notLoggedIn: return "请先登录"
        case .requestFailed: return "请求失败，请稍后重试"
        case .invalidResponse: return "AI 返回异常"
        case .noContent: return "没有可处理的内容"
        case .dailyLimitReached: return "今日 AI 额度已用完，明天再来"
        case .paymentRequired: return "请先购买"
        }
    }
}

/// Supported AI providers (used to construct payloads; all go through backend proxy)
public enum AIProvider: String, CaseIterable, Codable {
    case deepseek = "deepseek"

    public var displayName: String { "DeepSeek" }
    public var defaultModel: String { "deepseek-chat" }
}

/// Configuration for the AI service (provider + model only; no API key exposed to user)
public struct AIConfig {
    public var provider: AIProvider
    public var model: String

    public init(provider: AIProvider = .deepseek, model: String? = nil) {
        self.provider = provider
        self.model = model ?? provider.defaultModel
    }
}

@MainActor
public final class AIService: ObservableObject {
    @Published public var config = AIConfig()

    private let session: URLSession
    private let authService: AuthService

    /// Backend Edge Function URL
    private var proxyURL: URL {
        URL(string: "\(SupabaseConfig.url)/functions/v1/\(SupabaseConfig.aiProxyFunction)")!
    }

    public init(authService: AuthService) {
        let urlConfig = URLSessionConfiguration.default
        urlConfig.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: urlConfig)
        self.authService = authService
    }

    /// Generate a concise AI summary of the given HTML content
    public func summarize(html: String, title: String) async throws -> String {
        guard authService.isLoggedIn, let token = authService.accessToken else {
            throw AIServiceError.notLoggedIn
        }

        let plainText = stripHTML(html)
        guard !plainText.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIServiceError.noContent
        }

        let systemPrompt = "你是一个专业的文章摘要助手。"
        let userPrompt = """
        请用简短中文总结以下文章的核心内容（3-5句话），直接给出总结，不要前缀：

        标题：\(title)

        正文：
        \(String(plainText.prefix(4000)))
        """

        return try await proxyRequest(
            token: token,
            action: "summarize",
            systemPrompt: systemPrompt,
            userPrompt: userPrompt
        )
    }

    /// Translate HTML content to the target language
    public func translate(html: String, to language: TranslationLanguage) async throws -> String {
        guard authService.isLoggedIn, let token = authService.accessToken else {
            throw AIServiceError.notLoggedIn
        }

        let plainText = stripHTML(html)
        guard !plainText.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIServiceError.noContent
        }

        let systemPrompt = "你是一个专业的翻译助手。"
        let userPrompt = """
        请将以下文章翻译为\(language.displayName)，保持原文格式和语气，直接给出译文：

        \(String(plainText.prefix(4000)))
        """

        return try await proxyRequest(
            token: token,
            action: "translate",
            systemPrompt: systemPrompt,
            userPrompt: userPrompt
        )
    }

    // MARK: - Config persistence (no Keychain — provider/model only)

    private var configFileURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("NewReader/ai_config.json")
    }

    public func saveConfig() {
        guard let url = configFileURL else { return }
        let dict: [String: String] = [
            "provider": config.provider.rawValue,
            "model": config.model
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url)
    }

    public func loadConfig() {
        guard let url = configFileURL,
              let data = try? Data(contentsOf: url),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return }
        if let raw = dict["provider"], let provider = AIProvider(rawValue: raw) {
            config.provider = provider
        }
        if let model = dict["model"] {
            config.model = model
        }
    }

    // MARK: - Private
    // MARK: - Workspace analysis

    /// Analyze reading patterns: extract keywords and relationships from recent article titles.
    /// Analyze reading patterns: extract keywords and relationships from recent article titles.
    /// Returns JSON dict with "keywords", "relations", "summary" keys.
    public func analyzeReadingPatterns(titles: [String]) async throws -> WorkspaceAnalysisResult {
        guard authService.isLoggedIn, let token = authService.accessToken else {
            throw AIServiceError.notLoggedIn
        }
        guard !titles.isEmpty else { throw AIServiceError.noContent }

        let titleList = titles.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        let systemPrompt = "你是一个专业的数据分析师，擅长从文本中提取结构化的洞察。只输出JSON，不输出任何其他内容。"
        let userPrompt = """
        以下是我过去7天阅读的文章标题列表：
        \(titleList)

        请完成两件事：
        1. 用一句中文总结我的阅读兴趣主题（不超过50字）
        2. 提取5-10个核心关键词，并描述它们之间的关联

        请严格输出JSON格式（不要包含markdown代码块标记），格式如下：
        {"summary":"一句话总结","keywords":["K1","K2","K3"],"relations":[{"source":"K1","target":"K2","weight":1.0}]}

        其中 relations 中 weight 表示关联强度，按你认为的重要性从 0.1 到 2.0 取值。
        """

        let raw = try await proxyRequest(
            token: token,
            action: "analyze",
            systemPrompt: systemPrompt,
            userPrompt: userPrompt
        )
        return try parseAnalysisResult(raw)
    }

    private func parseAnalysisResult(_ raw: String) throws -> WorkspaceAnalysisResult {
        // Strip potential markdown code fences
        var cleaned = raw
        if let start = cleaned.range(of: "```"), let end = cleaned.range(of: "```", options: .backwards) {
            let contentStart = cleaned.index(after: cleaned[start].last == "\n" ? cleaned.index(after: start.upperBound) : start.upperBound)
            cleaned = String(cleaned[contentStart..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Remove trailing commas before closing brackets/braces
        cleaned = cleaned.replacingOccurrences(of: ",\n]", with: "\n]")
        cleaned = cleaned.replacingOccurrences(of: ",]", with: "]")
        cleaned = cleaned.replacingOccurrences(of: ",\n}", with: "\n}")
        cleaned = cleaned.replacingOccurrences(of: ",}", with: "}")

        guard let data = cleaned.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(WorkspaceAnalysisResult.self, from: data)
        } catch {
            // Fallback: try to extract at least the summary
            if let range = cleaned.range(of: "\"summary\":\""),
               let endRange = cleaned.range(of: "\"", range: range.upperBound..<cleaned.endIndex) {
                let summary = String(cleaned[range.upperBound..<endRange.lowerBound])
                return WorkspaceAnalysisResult(summary: summary, keywords: [], relations: [])
            }
            throw AIServiceError.invalidResponse
        }
    }

    private func proxyRequest(token: String, action: String, systemPrompt: String, userPrompt: String) async throws -> String {
        let body: [String: Any] = [
            "provider": config.provider.rawValue,
            "action": action,
            "model": config.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "params": [
                "temperature": 0.3,
                "max_tokens": 1024
            ]
        ]

        var request = URLRequest(url: proxyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw AIServiceError.invalidResponse
            }
            return AIService.stripThinking(content)

        case 401:
            throw AIServiceError.notLoggedIn
        case 402:
            throw AIServiceError.paymentRequired
        case 429:
            throw AIServiceError.dailyLimitReached
        default:
            throw AIServiceError.requestFailed
        }
    }

    /// Strip `<think>...</think>` blocks from model output (DeepSeek-R1, Claude, etc.)
    public static func stripThinking(_ text: String) -> String {
        var result = text
        while let start = result.range(of: "<think>"),
              let end = result.range(of: "</think>", range: start.upperBound..<result.endIndex) {
            result.removeSubrange(start.lowerBound..<end.upperBound)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stripHTML(_ html: String) -> String {
        HTMLSanitizer.toPlainText(html)
    }
}

// MARK: - Workspace types

/// Structured result from the reading-pattern analysis AI call.
public struct WorkspaceAnalysisResult: Codable {
    public var summary: String
    public var keywords: [String]
    public var relations: [KeywordRelation]

    public init(summary: String, keywords: [String], relations: [KeywordRelation]) {
        self.summary = summary
        self.keywords = keywords
        self.relations = relations
    }
}
