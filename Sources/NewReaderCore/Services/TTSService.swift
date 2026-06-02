import AVFoundation
import Combine

/// Manages text-to-speech playback with controls
@MainActor
public final class TTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
@Published public var isSpeaking: Bool = false
@Published public var isPaused: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var pendingText: String?
    private var rate: Float = AVSpeechUtteranceDefaultSpeechRate

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Start speaking the given text
    public func speak(_ text: String, language: String = "zh-CN") {
        let plainText = stripHTML(text)
        guard !plainText.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: plainText)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        currentUtterance = utterance
        pendingText = plainText
        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false
    }

    /// Pause playback, can resume later
    public func pause() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
    }

    /// Resume after pause
    public func resume() {
        synthesizer.continueSpeaking()
        isPaused = false
    }

    /// Stop playback entirely
    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentUtterance = nil
    }

    /// Adjust speaking rate (0.0 – 1.0, where 0.5 is default).
    /// If already speaking the utterance is restarted at the new rate.
    public func setRate(_ newRate: Float) {
        rate = AVSpeechUtteranceMinimumSpeechRate + newRate * (AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate)
        guard synthesizer.isSpeaking, let text = pendingText ?? currentUtterance?.speechString else { return }
        let wasPaused = isPaused
        let lang = currentUtterance?.voice?.language ?? "zh-CN"
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: lang)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        currentUtterance = utterance
        synthesizer.speak(utterance)
        if wasPaused { synthesizer.pauseSpeaking(at: .word) }
        isSpeaking = true
        isPaused = wasPaused
    }

    /// Available voice languages on the device
    static func availableLanguages() -> [(code: String, name: String)] {
        [
            ("zh-CN", "中文（普通话）"),
            ("en-US", "English (US)"),
            ("ja-JP", "日本語"),
            ("ko-KR", "한국어")
        ]
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPaused = true
        }
    }

    // MARK: - Private

    private func stripHTML(_ html: String) -> String {
        HTMLSanitizer.toPlainText(html)
    }
}
