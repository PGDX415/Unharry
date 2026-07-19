//
//  StoryPlayerViewModel.swift
//  Unhurry
//

import SwiftUI
import Observation

/// 睡前故事/冥想播放 ViewModel。
///
/// 管理 TTS 朗读状态 + 文字稿同步高亮。
@MainActor
@Observable
final class StoryPlayerViewModel {

    // MARK: - Published State

    private(set) var currentStory: StoryItem?
    private(set) var isPlaying = false
    private(set) var isPaused = false
    /// 当前高亮文字在全文中的位置（用于滚动同步）
    private(set) var highlightedRange: NSRange?

    // MARK: - Dependencies

    private let ttsService: TTSService
    private let sleepTimer: SleepTimer
    let stories: [StoryItem]

    // MARK: - Init

    init(ttsService: TTSService = TTSService(),
         sleepTimer: SleepTimer,
         stories: [StoryItem] = StoryItem.builtIn) {
        self.ttsService = ttsService
        self.sleepTimer = sleepTimer
        self.stories = stories
        self.ttsService.delegate = self

        // 计时结束时自动停止 TTS（链式挂载，不覆盖已有回调）
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
        if isPlaying { stop() }

        currentStory = story
        isPlaying = true
        isPaused = false
        highlightedRange = NSRange(location: 0, length: 0)
        ttsService.speak(story.content)
    }

    func togglePause() {
        if isPaused {
            ttsService.resume()
            isPaused = false
        } else {
            ttsService.pause()
            isPaused = true
        }
    }

    func stop() {
        ttsService.stop()
        isPlaying = false
        isPaused = false
        currentStory = nil
        highlightedRange = nil
    }

    /// 快进：从指定位置重新开始朗读。
    func seek(to characterIndex: Int) {
        guard let story = currentStory, characterIndex < story.content.count else { return }
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
