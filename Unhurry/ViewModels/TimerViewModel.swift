//
//  TimerViewModel.swift
//  Unhurry
//

import SwiftUI
import Observation

/// 睡眠计时器 ViewModel。
///
/// 桥接 `SleepTimer` 到 SwiftUI：
/// - 格式化剩余时间
/// - 管理预设时长选项
/// - 提供启动/取消操作
@MainActor
@Observable
final class TimerViewModel {

    // MARK: - Published State

    private(set) var remainingTime: TimeInterval = 0
    private(set) var isRunning = false

    // MARK: - Dependencies

    private let sleepTimer: SleepTimer

    // MARK: - Presets

    /// 预设时长选项（分钟）
    let presets: [(label: String, seconds: TimeInterval)] = [
        ("15 分钟", 15 * 60),
        ("30 分钟", 30 * 60),
        ("45 分钟", 45 * 60),
        ("60 分钟", 60 * 60),
    ]

    // MARK: - Init

    init(sleepTimer: SleepTimer) {
        self.sleepTimer = sleepTimer
        setupCallbacks()
    }

    // MARK: - Computed

    /// 格式化的剩余时间字符串（mm:ss）
    var formattedTime: String {
        let m = Int(remainingTime) / 60
        let s = Int(remainingTime) % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Actions

    func start(duration: TimeInterval) {
        // 淡出时长 = 总时长的 10%，最少 10 秒
        let fadeOutDuration = max(10, duration * 0.10)
        sleepTimer.start(duration: duration, fadeOutDuration: fadeOutDuration)
    }

    func cancel() {
        sleepTimer.cancel()
    }

    // MARK: - Private

    private func setupCallbacks() {
        sleepTimer.onTick = { [weak self] remaining in
            guard let self else { return }
            Task { @MainActor in
                self.remainingTime = remaining
                self.isRunning = true
            }
        }
        sleepTimer.onFinish = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.isRunning = false
                self.remainingTime = 0
            }
        }
        sleepTimer.onCancel = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.isRunning = false
                self.remainingTime = 0
            }
        }
    }
}
