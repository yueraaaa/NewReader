import Foundation

/// Language codes supported for translation
public enum TranslationLanguage: String, CaseIterable {
    case zh = "zh"    // Chinese
    case en = "en"    // English
    case ja = "ja"    // Japanese
    case ko = "ko"    // Korean

    var displayName: String {
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

/// Configuration for the AI service
public struct AIConfig {
    public var endpoint: String
    public var apiKey: String
    public var model: String

    public init(endpoint: String = "https://api.openai.com/v1",
                apiKey: String = "",
                model: String = "gpt-4o-mini") {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.model = model
    }
}

@MainActor
public final class AIService: ObservableObject {
    @Published public var config = AIConfig()

    private let session: URLSession
    private let keychainKey = "ai_api_key"
    private let endpointUDKey = "ai_endpoint"
    private let modelUDKey = "ai_model"

    public init() {
        let urlConfig = URLSessionConfiguration.default
        urlConfig.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: urlConfig)
        loadConfig()
    }

    /// Generate a concise AI summary of the given HTML content
    public func summarize(html: String, title: String) async throws -> String {
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
        if !config.apiKey.isEmpty {
            KeychainHelper.save(key: keychainKey, value: config.apiKey)
        } else {
            KeychainHelper.delete(key: keychainKey)
        }
        UserDefaults.standard.set(config.endpoint, forKey: endpointUDKey)
        UserDefaults.standard.set(config.model, forKey: modelUDKey)
    }

    /// Load API key from Keychain; non-sensitive fields from UserDefaults.
    /// Falls back to legacy plaintext file for one-time migration.
    private func loadConfig() {
        if let key = KeychainHelper.load(key: keychainKey), !key.isEmpty {
            self.config.apiKey = key
        } else if let legacy = loadLegacyConfig() {
            self.config.apiKey = legacy.apiKey
            if !legacy.apiKey.isEmpty {
                KeychainHelper.save(key: keychainKey, value: legacy.apiKey)
            }
            self.config.endpoint = legacy.endpoint
            self.config.model = legacy.model
        }

        if let endpoint = UserDefaults.standard.string(forKey: endpointUDKey),
           !endpoint.isEmpty {
            self.config.endpoint = endpoint
        }
        if let model = UserDefaults.standard.string(forKey: modelUDKey),
           !model.isEmpty {
            self.config.model = model
        }
    }

    /// One-time migration: read and delete the old plaintext config file.
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

    /// Validate and construct the chat completions URL.
    private func chatURL() throws -> URL {
        let raw = config.endpoint.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(raw)/chat/completions"),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" else {
            throw AIServiceError.insecureEndpoint
        }
        return url
    }

    private func chat(prompt: String, systemPrompt: String) async throws -> String {
        let url = try chatURL()

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

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stripHTML(_ html: String) -> String {
        guard let data = html.data(using: .utf8) else { return html }
        if let plain = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ).string {
            return plain
        }
        return html
    }
}

/// Legacy config struct used only for one-time migration.
private struct LegacyAIConfig: Codable {
    var endpoint: String
    var apiKey: String
    var model: String
}
