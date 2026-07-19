//
//  SleepTimer.swift
//  Unhurry
//

import Foundation

// MARK: - Sleep Timer

/// 睡眠计时器。
///
/// 实现 CLAUDE.md 中「定时渐弱停止播放」的核心逻辑：
/// 1. 用户设定时长（如 30 分钟）
/// 2. 倒数计时
/// 3. 在结束前 `fadeOutDuration` 秒触发所有活跃音轨的淡出
/// 4. 计时归零后停止音频引擎
///
/// ## 使用方式
/// ```swift
/// let timer = SleepTimer(audioService: audioService)
/// timer.onTick = { remaining in ... }
/// timer.onFinish = { ... }
/// timer.start(duration: 1800, fadeOutDuration: 30) // 30 分钟，最后 30 秒渐弱
/// ```
final class SleepTimer {

    // MARK: - Callbacks（闭包而非 delegate，兼容 struct 类型如 SwiftUI View）

    /// 每秒回调，参数为剩余秒数
    var onTick: ((TimeInterval) -> Void)?

    /// 计时正常结束（淡出完成）
    var onFinish: (() -> Void)?

    /// 计时被用户取消
    var onCancel: (() -> Void)?

    // MARK: - Properties

    /// 是否正在运行
    private(set) var isRunning = false

    /// 剩余时间（秒）
    private(set) var remainingTime: TimeInterval = 0

    // MARK: - Private

    private let audioService: AudioServiceProtocol
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.unhurry.sleeptimer")

    /// 计时终点
    private var endDate: Date = .distantPast

    /// 开始淡出的时间点（= endDate - fadeOutDuration）
    private var fadeStartDate: Date = .distantPast

    /// 淡出时长
    private var fadeOutDuration: TimeInterval = 0

    /// 防止重复触发淡出
    private var fadeTriggered = false

    // MARK: - Init

    init(audioService: AudioServiceProtocol) {
        self.audioService = audioService
    }

    deinit {
        timer?.cancel()
    }

    // MARK: - Public Methods

    /// 启动计时器。
    /// - Parameters:
    ///   - duration: 总时长（秒）
    ///   - fadeOutDuration: 结束前多长时间开始淡出（秒），0 表示立即停止
    func start(duration: TimeInterval, fadeOutDuration: TimeInterval = 30) {
        cancel()

        let now = Date()
        endDate = now.addingTimeInterval(duration)
        fadeStartDate = endDate.addingTimeInterval(-fadeOutDuration)
        self.fadeOutDuration = fadeOutDuration
        fadeTriggered = false
        isRunning = true
        remainingTime = duration

        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.schedule(deadline: .now(), repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.handleTick()
        }
        timer.resume()
        self.timer = timer
    }

    /// 取消计时器（不触发淡出，立即停止）。
    func cancel() {
        timer?.cancel()
        timer = nil
        let wasRunning = isRunning
        isRunning = false
        remainingTime = 0
        fadeTriggered = false

        if wasRunning {
            DispatchQueue.main.async { [weak self] in
                self?.onCancel?()
            }
        }
    }

    // MARK: - Private

    private func handleTick() {
        let now = Date()
        let remaining = max(0, endDate.timeIntervalSince(now))
        self.remainingTime = remaining

        // 回调 UI 层
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onTick?(self.remainingTime)
        }

        // 淡出触发点：到达 fadeStartDate 且尚未触发
        if !fadeTriggered && now >= fadeStartDate && remaining > 0 {
            fadeTriggered = true
            triggerFadeOut(remainingDuration: remaining)
        }

        // 计时结束
        if remaining <= 0 {
            timer?.cancel()
            timer = nil
            isRunning = false

            // 确保引擎停止
            audioService.stopEngine()

            DispatchQueue.main.async { [weak self] in
                self?.onFinish?()
            }
        }
    }

    /// 对所有活跃音轨启动淡出。
    private func triggerFadeOut(remainingDuration: TimeInterval) {
        let soundIds = audioService.activeSoundIds
        guard !soundIds.isEmpty else { return }

        // 每个音轨渐弱到 0，计时结束时统一 stopEngine
        for id in soundIds {
            audioService.fadeOut(soundId: id, duration: remainingDuration, completion: nil)
        }
    }
}
