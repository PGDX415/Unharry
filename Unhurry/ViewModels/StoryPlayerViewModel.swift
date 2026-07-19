//
//  StoryPlayerViewModel.swift
//  Unhurry
//

import SwiftUI
import Observation
import AVFoundation

/// 睡前故事/冥想播放 ViewModel。
///
/// 管理两种播放模式：
/// - **TTS 模式**：AVSpeechSynthesizer 实时合成，delegate 提供精确字级时间戳
/// - **音频模式**：AVAudioPlayer 播放预录音频，Timer 同步文字稿进度
@MainActor
@Observable
final class StoryPlayerViewModel {

    // MARK: - Published State

    private(set) var currentStory: StoryItem?
    private(set) var isPlaying = false
    private(set) var isPaused = false
    /// 播放前的准备缓冲状态（给用户闭眼/躺好的时间）
    private(set) var isPreparing = false
    /// 当前高亮文字在全文中的位置（用于滚动同步）
    private(set) var highlightedRange: NSRange?
    /// 是否为预录音频模式（而非 TTS）
    private(set) var isAudioMode = false

    // MARK: - Constants

    /// 播放前准备缓冲时间（秒）
    static let prepareDelay: TimeInterval = 3.0

    // MARK: - Dependencies

    private let ttsService: TTSService
    private let sleepTimer: SleepTimer
    let stories: [StoryItem]

    // MARK: - Audio Mode Properties

    private var audioPlayer: AVAudioPlayer?
    private var syncTimer: Timer?
    private var prepareTimer: Timer?
    /// 音频模式下的累计播放时长（用于暂停/恢复追踪）
    private var audioElapsed: TimeInterval = 0
    private var syncTimerStartDate: Date?

    // MARK: - Init

    init(ttsService: TTSService = TTSService(),
         sleepTimer: SleepTimer,
         stories: [StoryItem] = StoryItem.builtIn) {
        self.ttsService = ttsService
        self.sleepTimer = sleepTimer
        self.stories = stories
        self.ttsService.delegate = self

        // 计时结束时自动停止播放（链式挂载，不覆盖已有回调）
        let oldFinish = sleepTimer.onFinish
        sleepTimer.onFinish = { [weak self] in
            self?.stop()
            oldFinish?()
        }
        let oldCancel = sleepTimer.onCancel
        sleepTimer.onCancel = { [weak self] in
            self?.stop()
            oldCancel?()
        }
    }

    // MARK: - Actions

    func play(_ story: StoryItem) {
        // 如果正在播别的，先停
        if isPlaying || isPreparing { stop() }

        currentStory = story
        isPreparing = true
        highlightedRange = nil

        // 准备缓冲后自动开始播放
        prepareTimer?.invalidate()
        prepareTimer = Timer.scheduledTimer(withTimeInterval: Self.prepareDelay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.startPlayback(story)
            }
        }
    }

    /// 跳过准备缓冲，立即开始播放。
    func skipPreparation() {
        guard isPreparing, let story = currentStory else { return }
        prepareTimer?.invalidate()
        prepareTimer = nil
        isPreparing = false
        startPlayback(story)
    }

    func togglePause() {
        if isAudioMode {
            toggleAudioPause()
        } else {
            toggleTTSPause()
        }
    }

    func stop() {
        // 清理准备计时器
        prepareTimer?.invalidate()
        prepareTimer = nil

        // 清理音频播放器
        syncTimer?.invalidate()
        syncTimer = nil
        syncTimerStartDate = nil
        audioPlayer?.stop()
        audioPlayer = nil

        // 清理 TTS
        ttsService.stop()

        isPlaying = false
        isPaused = false
        isPreparing = false
        isAudioMode = false
        currentStory = nil
        highlightedRange = nil
    }

    /// 快进/快退：跳转到指定字符位置重新开始。
    func seek(to characterIndex: Int) {
        guard let story = currentStory, characterIndex < story.content.count else { return }

        if isAudioMode {
            seekAudio(to: characterIndex)
        } else {
            seekTTS(to: characterIndex)
        }
    }

    // MARK: - Private: Start Playback

    /// 准备缓冲结束后实际开始播放。
    private func startPlayback(_ story: StoryItem) {
        isPreparing = false
        isPlaying = true
        isPaused = false

        if story.hasAudio {
            playAudio(story)
        } else {
            playTTS(story)
        }
    }

    // MARK: - Private: Audio Mode

    private func playAudio(_ story: StoryItem) {
        guard let fileName = story.audioFileName else {
            // 降级到 TTS
            playTTS(story)
            return
        }

        guard let url = Bundle.main.url(
            forResource: fileName,
            withExtension: story.audioFileExtension,
            subdirectory: nil
        ) else {
            print("⚠️  Story audio file missing: \(fileName).\(story.audioFileExtension), falling back to TTS")
            playTTS(story)
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            audioPlayer = player
            isAudioMode = true
            highlightedRange = NSRange(location: 0, length: 0)
            audioElapsed = 0
            startAudioSyncTimer(story: story)
        } catch {
            print("❌ Failed to play audio story: \(error), falling back to TTS")
            playTTS(story)
        }
    }

    private func toggleAudioPause() {
        guard let player = audioPlayer else { return }
        if isPaused {
            player.play()
            isPaused = false
            startAudioSyncTimer(story: currentStory!)
        } else {
            player.pause()
            isPaused = true
            syncTimer?.invalidate()
            syncTimer = nil
            syncTimerStartDate = nil
            // 记录当前累计时长
            audioElapsed += Date().timeIntervalSince(syncTimerStartDate ?? Date())
        }
    }

    private func seekAudio(to characterIndex: Int) {
        guard let player = audioPlayer, let story = currentStory, player.duration > 0 else { return }
        let seekTime = player.duration * Double(characterIndex) / Double(story.content.count)
        player.currentTime = seekTime
        audioElapsed = seekTime
        highlightedRange = NSRange(location: 0, length: characterIndex)
        if isPaused {
            isPaused = false
            player.play()
        }
        startAudioSyncTimer(story: story)
    }

    /// 启动进度同步计时器（~10Hz），根据播放位置更新文字高亮。
    private func startAudioSyncTimer(story: StoryItem) {
        syncTimer?.invalidate()
        syncTimerStartDate = Date()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncHighlight(story: story)
            }
        }
        RunLoop.main.add(syncTimer!, forMode: .common)
    }

    private func syncHighlight(story: StoryItem) {
        guard let player = audioPlayer, player.duration > 0 else { return }

        let elapsed = audioElapsed + Date().timeIntervalSince(syncTimerStartDate ?? Date())
        let progress = min(1.0, max(0.0, elapsed / player.duration))
        let charPos = Int(progress * Double(story.content.count))

        // 卡拉 OK 式渐进高亮：从开头到当前位置全部高亮
        highlightedRange = NSRange(location: 0, length: charPos)

        // 播放完毕自动停止
        if !player.isPlaying && progress >= 0.99 {
            syncTimer?.invalidate()
            syncTimer = nil
            syncTimerStartDate = nil
            isPlaying = false
            isPaused = false
        }
    }

    // MARK: - Private: TTS Mode

    private func playTTS(_ story: StoryItem) {
        isAudioMode = false
        highlightedRange = NSRange(location: 0, length: 0)
        ttsService.speak(story.content)
    }

    private func toggleTTSPause() {
        if isPaused {
            ttsService.resume()
            isPaused = false
        } else {
            ttsService.pause()
            isPaused = true
        }
    }

    private func seekTTS(to characterIndex: Int) {
        guard let story = currentStory else { return }
        let remaining = String(story.content.dropFirst(characterIndex))
        ttsService.stop()
        ttsService.speak(remaining)
        highlightedRange = NSRange(location: characterIndex, length: 0)
    }
}

// MARK: - TTSServiceDelegate

extension StoryPlayerViewModel: TTSServiceDelegate {
    nonisolated func ttsService(_ service: TTSService, willSpeak range: NSRange, of string: String) {
        Task { @MainActor in
            self.highlightedRange = range
        }
    }

    nonisolated func ttsServiceDidFinish(_ service: TTSService) {
        Task { @MainActor in
            self.isPlaying = false
            self.isPaused = false
        }
    }

    nonisolated func ttsServiceDidPause(_ service: TTSService) {
        // 由 togglePause 处理状态
    }
}
