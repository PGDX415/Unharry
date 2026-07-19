//
//  BreathViewModel.swift
//  Unhurry
//

import SwiftUI
import Observation
import CoreHaptics

/// 呼吸引导练习 ViewModel。
///
/// 管理呼吸节奏动画 + CoreHaptics 同步震动。
@MainActor
@Observable
final class BreathViewModel {

    // MARK: - Phase

    enum Phase: String {
        case inhale = "吸气"
        case exhale = "呼气"

        /// 该阶段持续秒数
        var duration: TimeInterval {
            switch self {
            case .inhale: return 4.0
            case .exhale: return 6.0
            }
        }
    }

    // MARK: - State

    enum State {
        case idle
        case running
        case paused
        case finished
    }

    private(set) var state: State = .idle
    private(set) var currentPhase: Phase = .inhale
    /// 当前阶段进度 0...1
    private(set) var phaseProgress: Double = 0
    /// 已完成呼吸次数
    private(set) var breathCount: Int = 0
    /// 已过时间（秒）
    private(set) var elapsed: TimeInterval = 0
    /// 总时长（秒）
    private(set) var totalDuration: TimeInterval = 300
    /// 缩放动画值（吸=1.3, 呼=1.0）
    private(set) var scale: Double = 1.0

    /// 可用预设时长
    let presets: [(String, TimeInterval)] = [
        ("3 分钟", 180),
        ("5 分钟", 300),
        ("10 分钟", 600),
    ]

    // MARK: - Haptics

    private var hapticEngine: CHHapticEngine?
    private var hapticPlayer: CHHapticPatternPlayer?
    private var supportsHaptics = false

    // MARK: - Timer

    private var displayLink: CADisplayLink?
    private var phaseStartDate: Date = .now

    // MARK: - Init

    init() {
        setupHaptics()
    }

    // MARK: - Actions

    func selectPreset(seconds: TimeInterval) {
        totalDuration = seconds
    }

    func start() {
        guard state != .running else { return }
        state = .running
        breathCount = 0
        elapsed = 0
        currentPhase = .inhale
        phaseProgress = 0
        phaseStartDate = .now
        scale = 1.0
        startPhaseHaptics()
        startDisplayLink()
    }

    func togglePause() {
        switch state {
        case .running:
            state = .paused
            stopDisplayLink()
            stopHaptics()
        case .paused:
            state = .running
            phaseStartDate = .now.addingTimeInterval(
                -currentPhase.duration * phaseProgress
            )
            startPhaseHaptics()
            startDisplayLink()
        default: break
        }
    }

    func stop() {
        state = .idle
        stopDisplayLink()
        stopHaptics()
        phaseProgress = 0
        scale = 1.0
    }

    // MARK: - Display Link

    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60)
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private nonisolated func tick() {
        Task { @MainActor in
            updateProgress()
        }
    }

    private func updateProgress() {
        guard state == .running else { return }

        let now = Date()
        let phaseElapsed = now.timeIntervalSince(phaseStartDate)
        let duration = currentPhase.duration
        phaseProgress = min(1.0, phaseElapsed / duration)

        // 更新缩放动画
        switch currentPhase {
        case .inhale:
            scale = 1.0 + 0.3 * phaseProgress  // 1.0 → 1.3
        case .exhale:
            scale = 1.3 - 0.3 * phaseProgress  // 1.3 → 1.0
        }

        // 阶段切换
        if phaseProgress >= 1.0 {
            switch currentPhase {
            case .inhale:
                currentPhase = .exhale
            case .exhale:
                currentPhase = .inhale
                breathCount += 1
            }
            phaseProgress = 0
            phaseStartDate = now
            startPhaseHaptics()
        }

        // 总时长检查
        elapsed += 1.0 / 60.0
        if elapsed >= totalDuration {
            state = .finished
            stopDisplayLink()
            stopHaptics()
        }
    }

    // MARK: - Haptics

    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        supportsHaptics = true
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            hapticEngine?.resetHandler = { [weak self] in
                Task { @MainActor in
                    try? self?.hapticEngine?.start()
                }
            }
        } catch {
            print("⚠️ Haptic engine init failed: \(error)")
        }
    }

    private func startPhaseHaptics() {
        guard supportsHaptics, let engine = hapticEngine else { return }

        let duration = currentPhase.duration
        let startIntensity: Float = currentPhase == .inhale ? 0.3 : 0.8
        let endIntensity: Float   = currentPhase == .inhale ? 0.8 : 0.3

        do {
            let intensityParam = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: startIntensity
            )
            let sharpnessParam = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: 0.5
            )
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensityParam, sharpnessParam],
                relativeTime: 0,
                duration: duration
            )

            // 渐变强度曲线
            let intensityCurve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0, value: startIntensity),
                    .init(relativeTime: duration, value: endIntensity),
                ],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(
                events: [event],
                parameterCurves: [intensityCurve]
            )
            hapticPlayer = try engine.makePlayer(with: pattern)
            try hapticPlayer?.start(atTime: 0)
        } catch {
            // 静默降级，不影响主功能
        }
    }

    private func stopHaptics() {
        try? hapticPlayer?.cancel()
    }
}
