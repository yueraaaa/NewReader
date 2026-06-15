import AVFoundation
import Foundation

// MARK: - TTS Engine

public enum TTSEngine: CaseIterable {
    case apple
    case custom

    public var displayName: String {
        switch self {
        case .apple: return "Apple 系统语音"
        case .custom: return "自定义 TTS API"
        }
    }
}

// MARK: - Codable (backward-compatible: decodes legacy "minimax" too)
extension TTSEngine: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "minimax", "custom": self = .custom
        default: self = .apple
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - RawRepresentable (for Picker bindings)
extension TTSEngine: RawRepresentable {
    public var rawValue: String {
        switch self {
        case .apple: return "apple"
        case .custom: return "custom"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "apple": self = .apple
        case "minimax", "custom": self = .custom
        default: return nil
        }
    }
}

// MARK: - Custom TTS Config

public struct CustomTTSConfig: Codable {
    public init() {}
    public var engine: TTSEngine = .apple
    public var endpoint: String = "https://your-tts-api.example.com/v1/tts"
    public var voiceId: String = "male-qn-qingse"
    public var speed: Double = 1.0
    public var pitch: Double = 0
    public var volume: Double = 1.0

    /// Preset voice IDs (customize for your TTS provider)
    public static let voicePresets: [(id: String, name: String)] = [
        ("male-qn-qingse", "青涩青年男声"),
        ("male-qn-jingying", "精英青年男声"),
        ("female-shaonv", "少女"),
        ("female-yujie", "御姐"),
        ("presenter-male", "男主持人"),
        ("presenter-female", "女主持人"),
        ("female-shaonv", "少女"),
        ("audiobook-male-1", "有声书男声"),
        ("audiobook-female-1", "有声书女声"),
    ]

    private static let keychainKey = "tts_api_key"

    // MARK: - Persistence

    /// Load config from disk; API key from Keychain.
    public static func load() -> CustomTTSConfig {
        // Ensure config directory exists
        if let dir = configFileURL?.deletingLastPathComponent() {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        var config = CustomTTSConfig()
        if let url = configFileURL,
           let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode(CustomTTSConfig.self, from: data) {
            config = saved
        }
        if let key = KeychainHelper.load(key: keychainKey), !key.isEmpty {
            config.apiKey = key
        }
        return config
    }

    /// Save config to disk + Keychain. `apiKey` is excluded from JSON.
    public func save() {
        // Ensure config directory exists
        if let dir = Self.configFileURL?.deletingLastPathComponent() {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        // Save API key to Keychain
        if !apiKey.isEmpty {
            KeychainHelper.save(key: Self.keychainKey, value: apiKey)
        } else {
            KeychainHelper.delete(key: Self.keychainKey)
        }

        // Encode numeric fields
        if let data = try? JSONEncoder().encode(self) {
            if var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                json.removeValue(forKey: "apiKey")
                if let clean = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                    try? clean.write(to: Self.configFileURL!, options: .atomic)
                }
            }
        }
    }

    private static var configFileURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("NewReader/tts_config.json")
    }

    // API key is transient — load from Keychain, never persists in JSON
    public var apiKey: String = ""

    enum CodingKeys: String, CodingKey {
        case engine, endpoint, voiceId, speed, pitch, volume
    }
}

// MARK: - Custom TTS Provider

@MainActor
public final class CustomTTSProvider: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published public var isSpeaking: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    public var config: CustomTTSConfig

    private let session: URLSession
    private var player: AVAudioPlayer?
    private var tempAudioURL: URL?

    public init(config: CustomTTSConfig) {
        self.config = config
        let urlConfig = URLSessionConfiguration.default
        urlConfig.timeoutIntervalForRequest = 60
        urlConfig.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: urlConfig)
        super.init()
    }

    /// Speak the given text via TTS API.
    /// Fails gracefully — the caller should fall back to Apple TTS.
    public func speak(_ text: String) async -> Bool {
        let key = config.apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else {
            errorMessage = "API Key 为空，请先填写并保存。"
            return false
        }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        stop()
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let endpoint = config.endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: endpoint),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" else {
            errorMessage = "API 端点必须使用 HTTPS"
            return false
        }

        let body: [String: Any] = [
            "model": "speech-2.8-hd",
            "text": text,
            "stream": false,
            "voice_setting": [
                "voice_id": config.voiceId,
                "speed": config.speed,
                "vol": config.volume,
                "pitch": config.pitch,
            ],
            "audio_setting": [
                "sample_rate": 32000,
                "bitrate": 128000,
                "format": "mp3",
                "channel": 1,
            ],
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                errorMessage = "TTS 响应格式异常"
                return false
            }
            guard http.statusCode == 200 else {
                errorMessage = "TTS 请求失败 (HTTP \(http.statusCode))"
                return false
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                // Don't echo the raw response body in the UI — it can carry the
                // user's API key (in echoed headers / debug fields) or PII. Log
                // it for debugging and surface a generic message instead.
                let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                CrashReporter.log("TTS 响应解析失败: HTTP \(http.statusCode), body (first 200 chars): \(raw.prefix(200))")
                errorMessage = "TTS 响应解析失败（HTTP \(http.statusCode)）。原始响应已写入日志：~/Library/Logs/NewReader/app.log"
                return false
            }

            // Check for API-level error
            if let br = json["base_resp"] as? [String: Any],
               let code = br["status_code"] as? Int, code != 0 {
                errorMessage = "TTS API 错误 (\(code)): \(br["status_msg"] as? String ?? "未知")"
                return false
            }

            // Extract audio — support both "data.audio" (base64) and "audio_url" forms
            var audioData: Data?
            if let d = json["data"] as? [String: Any],
               let audio64 = d["audio"] as? String,
               !audio64.isEmpty {
                audioData = decodeHex(audio64)
            }
            if audioData == nil, let raw64 = json["audio"] as? String, !raw64.isEmpty {
                audioData = decodeHex(raw64)
            }
            if audioData == nil, let d = json["data"] as? [String: Any],
               let audioURL = d["audio_url"] as? String,
               let url = URL(string: audioURL) {
                audioData = try? Data(contentsOf: url)
            }

            guard let audio = audioData else {
                errorMessage = "TTS 未返回有效音频数据"
                return false
            }

            return playAudio(audio)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Pause playback
    public func pause() {
        player?.pause()
        isPaused = true
    }

    /// Resume playback
    public func resume() {
        player?.play()
        isPaused = false
    }

    /// Stop playback and clean up temp file
    public func stop() {
        player?.stop()
        player = nil
        isSpeaking = false
        isPaused = false
        if let url = tempAudioURL {
            try? FileManager.default.removeItem(at: url)
            tempAudioURL = nil
        }
    }

    // MARK: - Private

    /// Decode a hex-encoded string (some TTS APIs return audio as hex, not base64).
    private func decodeHex(_ hex: String) -> Data? {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var idx = hex.startIndex
        for _ in 0..<len {
            let end = hex.index(idx, offsetBy: 2)
            guard let byte = UInt8(hex[idx..<end], radix: 16) else { return nil }
            data.append(byte)
            idx = end
        }
        return data
    }

    private func playAudio(_ data: Data) -> Bool {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("tts_\(UUID().uuidString).mp3")
        try? data.write(to: url, options: .atomic)
        tempAudioURL = url

        // Try initWithData (more format-tolerant than initWithContentsOfURL)
        do {
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            isSpeaking = true
            isPaused = false
            return true
        } catch {
            let prefix = data.prefix(4).map { String(format: "%02x", $0) }.joined(separator: " ")
            errorMessage = "[v2] 音频格式不支持 dataLen=\(data.count) hex=\(prefix): \(error.localizedDescription). 已保存桌面 tts_debug.mp3"
            return false
        }
    }

    // MARK: - AVAudioPlayerDelegate

    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            if let url = self.tempAudioURL {
                try? FileManager.default.removeItem(at: url)
                self.tempAudioURL = nil
            }
        }
    }
}
