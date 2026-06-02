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
}

public enum AIServiceError: LocalizedError {
    case notConfigured
    case requestFailed
    case invalidResponse
    case noContent
    case insecureEndpoint

    public var errorDescription: String? {
        switch self {
        case .notConfigured: return "请先配置 API Key"
        case .requestFailed: return "请求失败，请稍后重试"
        case .invalidResponse: return "AI 返回异常"
        case .noContent: return "没有可处理的内容"
        case .insecureEndpoint: return "API 端点必须使用 HTTPS"
        }
    }
}

/// Supported AI providers
public enum AIProvider: String, CaseIterable, Codable {
    case openAI = "openai"
    case anthropic = "anthropic"

    public var displayName: String {
        switch self {
        case .openAI: return "OpenAI 兼容"
        case .anthropic: return "Anthropic"
        }
    }

    public var defaultEndpoint: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        }
    }

    public var defaultModel: String {
        switch self {
        case .openAI: return "gpt-4o-mini"
        case .anthropic: return "claude-3-5-haiku-20241022"
        }
    }

    public var apiKeyPlaceholder: String {
        switch self {
        case .openAI: return "sk-…"
        case .anthropic: return "sk-ant-…"
        }
    }
}

/// Configuration for the AI service
public struct AIConfig {
    public var provider: AIProvider
    public var endpoint: String
    public var apiKey: String
    public var model: String

    public init(provider: AIProvider = .openAI,
                endpoint: String? = nil,
                apiKey: String = "",
                model: String? = nil) {
        self.provider = provider
        self.endpoint = endpoint ?? provider.defaultEndpoint
        self.apiKey = apiKey
        self.model = model ?? provider.defaultModel
    }
}

@MainActor
public final class AIService: ObservableObject {
    @Published public var config = AIConfig()

    private let session: URLSession
    private let keychainKey = "ai_api_key"

    private var configFileURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("NewReader/ai_config.json")
    }

    public init() {
        let urlConfig = URLSessionConfiguration.default
        urlConfig.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: urlConfig)
    }

    /// Ensure config is loaded from disk / Keychain. Call before any AI request.
    private func ensureConfigLoaded() {
        if !configLoaded { loadConfig() }
    }

    private var configLoaded = false

    /// Generate a concise AI summary of the given HTML content
    public func summarize(html: String, title: String) async throws -> String {
        ensureConfigLoaded()
        guard !config.apiKey.isEmpty else { throw AIServiceError.notConfigured }

        let plainText = stripHTML(html)
        guard !plainText.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIServiceError.noContent
        }

        let prompt = """
        请用简短中文总结以下文章的核心内容（3-5句话），直接给出总结，不要前缀：

        标题：\(title)

        正文：
        \(String(plainText.prefix(4000)))
        """

        return try await chat(prompt: prompt, systemPrompt: "你是一个专业的文章摘要助手。")
    }

    /// Translate HTML content to the target language
    public func translate(html: String, to language: TranslationLanguage) async throws -> String {
        ensureConfigLoaded()
        guard !config.apiKey.isEmpty else { throw AIServiceError.notConfigured }

        let plainText = stripHTML(html)
        guard !plainText.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIServiceError.noContent
        }

        let prompt = """
        请将以下文章翻译为\(language.displayName)，保持原文格式和语气，直接给出译文：

        \(String(plainText.prefix(4000)))
        """

        return try await chat(prompt: prompt, systemPrompt: "你是一个专业的翻译助手。")
    }

    // MARK: - Config persistence

    /// Save API key to Keychain; non-sensitive fields to UserDefaults.
    public func saveConfig() {
        // Save API key to Keychain
        if !config.apiKey.isEmpty {
            KeychainHelper.save(key: keychainKey, value: config.apiKey)
        } else {
            KeychainHelper.delete(key: keychainKey)
        }

        // Save non-sensitive config to JSON file
        let dict: [String: String] = [
            "provider": config.provider.rawValue,
            "endpoint": config.endpoint,
            "model": config.model
        ]
        guard let data = try? JSONEncoder().encode(dict),
              let url = configFileURL else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }

    /// Test the AI connection with current config. Returns nil on success, or error message.
    public func testConnection() async -> String? {
        guard !config.apiKey.isEmpty else { return "请先填写 API Key" }
        guard (config.endpoint.hasPrefix("https")) else { return "API 端点必须使用 HTTPS" }
        do {
            switch config.provider {
            case .openAI:
                _ = try await chatOpenAI(prompt: "reply with just: OK", systemPrompt: "")
            case .anthropic:
                _ = try await chatAnthropic(prompt: "reply with just: OK", systemPrompt: "")
            }
            return ""
        } catch {
            return error.localizedDescription
        }
    }

    /// Load API key from Keychain; non-sensitive fields from UserDefaults.
    private func loadConfig() {
        // Load API key from Keychain
        if let key = KeychainHelper.load(key: keychainKey), !key.isEmpty {
            self.config.apiKey = key
        }

        // Load non-sensitive config from JSON file
        if let url = configFileURL,
           let data = try? Data(contentsOf: url),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            if let raw = dict["provider"], let p = AIProvider(rawValue: raw) {
                self.config.provider = p
            }
            if let e = dict["endpoint"], !e.isEmpty {
                self.config.endpoint = e
            }
            if let m = dict["model"], !m.isEmpty {
                self.config.model = m
            }
        } else if let legacy = loadLegacyConfig() {
            // One-time migration from legacy config file
            self.config.provider = legacy.provider
            self.config.endpoint = legacy.endpoint
            self.config.model = legacy.model
            if !legacy.apiKey.isEmpty {
                self.config.apiKey = legacy.apiKey
                KeychainHelper.save(key: keychainKey, value: legacy.apiKey)
            }
            saveConfig()
        }
        configLoaded = true
    }

    private func loadLegacyConfig() -> AIConfig? {
        guard let url = legacyConfigFileURL,
              let data = try? Data(contentsOf: url),
              let legacy = try? JSONDecoder().decode(LegacyAIConfig.self, from: data)
        else { return nil }
        try? FileManager.default.removeItem(at: url)
        return AIConfig(endpoint: legacy.endpoint, apiKey: legacy.apiKey, model: legacy.model)
    }

    private var legacyConfigFileURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("NewReader/ai_config.json")
    }

    // MARK: - Private

    private func buildRequestURL() throws -> URL {
        let raw = config.endpoint.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let path: String
        switch config.provider {
        case .openAI:
            path = "\(raw)/chat/completions"
        case .anthropic:
            path = "\(raw)/messages"
        }

        guard let url = URL(string: path),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" else {
            throw AIServiceError.insecureEndpoint
        }
        return url
    }

    private func chat(prompt: String, systemPrompt: String) async throws -> String {
        switch config.provider {
        case .openAI:
            return try await chatOpenAI(prompt: prompt, systemPrompt: systemPrompt)
        case .anthropic:
            return try await chatAnthropic(prompt: prompt, systemPrompt: systemPrompt)
        }
    }

    // MARK: - OpenAI-compatible API

    private func chatOpenAI(prompt: String, systemPrompt: String) async throws -> String {
        let url = try buildRequestURL()

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 1024
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }

        return Self.stripThinking(content)
    }

    // MARK: - Anthropic Messages API

    private func chatAnthropic(prompt: String, systemPrompt: String) async throws -> String {
        let url = try buildRequestURL()

        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 1024,
            "messages": messages,
            "system": systemPrompt
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentList = json["content"] as? [[String: Any]],
              let firstBlock = contentList.first,
              let text = firstBlock["text"] as? String else {
            throw AIServiceError.invalidResponse
        }

        return Self.stripThinking(text)
    }

    // MARK: - Helpers

    /// Strip `<think>...</think>` blocks from model output (DeepSeek-R1, Claude, etc.).
    /// Exposed as `nonisolated static` so unit tests in NewReaderCoreTests can cover it directly.
    nonisolated static func stripThinking(_ text: String) -> String {
        var result = text
        while let start = result.range(of: "<think>"),
              let end = result.range(of: "</think>", range: start.upperBound..<result.endIndex) {
            result.removeSubrange(start.lowerBound..<end.upperBound)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    private func stripHTML(_ html: String) -> String {
        // Use the safe regex-based extractor so we never trigger remote
        // resource fetches (privacy) or stall waiting for image timeouts.
        HTMLSanitizer.toPlainText(html)
    }

}

/// Legacy config struct used only for one-time migration.
private struct LegacyAIConfig: Codable {
    var endpoint: String
    var apiKey: String
    var model: String
    var provider: AIProvider = .openAI
}
