//
//  TTSService.swift
//  Unhurry
//

import AVFoundation

// MARK: - TTS Service Delegate

protocol TTSServiceDelegate: AnyObject {
    /// 即将朗读某段文本时回调，用于同步滚动文字稿
    func ttsService(_ service: TTSService, willSpeak range: NSRange, of string: String)
    /// 朗读完成（自然结束）
    func ttsServiceDidFinish(_ service: TTSService)
    /// 朗读被暂停
    func ttsServiceDidPause(_ service: TTSService)
}

// MARK: - TTS Service

/// 文字转语音服务，封装 `AVSpeechSynthesizer`。
///
/// ## 用途
/// 原型阶段用于睡前故事/冥想的语音朗读。
/// CLAUDE.md 策略：短期用 TTS 验证，长期替换为专业配音音频。
///
/// ## 与 AudioService 的关系
/// TTS 朗读时，建议先暂停白噪音类循环音效（或降低其音量），
/// 避免遮蔽语音。此协调逻辑在 ViewModel 层处理。
final class TTSService: NSObject {

    // MARK: - Properties

    weak var delegate: TTSServiceDelegate?

    private let synthesizer = AVSpeechSynthesizer()

    private(set) var isSpeaking: Bool = false
    private(set) var isPaused: Bool = false

    /// 当前朗读的文本全文
    private(set) var currentText: String?

    // MARK: - Init

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public Methods

    /// 开始朗读文本。
    func speak(_ text: String, language: String = "zh-CN") {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85  // 稍慢，适合睡前

        currentText = text
        isSpeaking = true
        isPaused = false
        synthesizer.speak(utterance)
    }

    /// 暂停朗读。
    func pause() {
        guard isSpeaking, !isPaused else { return }
        synthesizer.pauseSpeaking(at: .immediate)
        isPaused = true
    }

    /// 继续朗读。
    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
    }

    /// 停止朗读。
    func stop() {
        guard isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentText = nil
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSService: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        guard let text = currentText else { return }
        // 确保 range 不越界
        let clampedRange = NSRange(
            location: min(characterRange.location, text.count),
            length: min(characterRange.length, text.count - min(characterRange.location, text.count))
        )
        delegate?.ttsService(self, willSpeak: clampedRange, of: text)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        currentText = nil
        delegate?.ttsServiceDidFinish(self)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        delegate?.ttsServiceDidPause(self)
    }
}
