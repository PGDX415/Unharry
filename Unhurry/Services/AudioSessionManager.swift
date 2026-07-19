//
//  AudioSessionManager.swift
//  Unhurry
//

import AVFoundation

/// 管理 `AVAudioSession` 的配置、激活/停用，以及音频中断处理。
///
/// 职责：
/// - 配置 `.playback` category 以支持后台播放
/// - 监听音频中断通知（如来电、闹钟）
/// - 通过 `interruptionHandler` 回调将中断事件传递给上层
final class AudioSessionManager {

    // MARK: - Types

    /// 音频中断类型
    enum InterruptionType {
        case began
        case ended(shouldResume: Bool)
    }

    // MARK: - Properties

    private let session: AVAudioSession
    private var isActive = false

    /// 中断回调。上层（如 `AudioService`）设置此闭包以响应中断。
    var interruptionHandler: ((InterruptionType) -> Void)?

    // MARK: - Init

    init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
        registerForInterruptionNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// 配置并激活音频会话（`.playback` category，支持后台播放）。
    func activate() throws {
        try session.setCategory(
            .playback,
            mode: .default,
            options: [.mixWithOthers]
        )
        try session.setActive(true)
        isActive = true
    }

    /// 停用音频会话，释放音频资源。
    func deactivate() throws {
        try session.setActive(false, options: .notifyOthersOnDeactivation)
        isActive = false
    }

    // MARK: - Interruption Handling

    private func registerForInterruptionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            // 音频中断开始（如来电）。系统已自动停用 session，
            // 上层应暂停播放。
            isActive = false
            interruptionHandler?(.began)

        case .ended:
            // 音频中断结束。检查是否应恢复播放。
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            let shouldResume = options.contains(.shouldResume)
            interruptionHandler?(.ended(shouldResume: shouldResume))

        @unknown default:
            break
        }
    }
}
