//
//  SleepRitualViewModel.swift
//  Unhurry
//

import SwiftUI
import Observation

/// 入睡仪式 ViewModel——按步骤编排呼吸 → 音效 → 计时器。
@MainActor
@Observable
final class SleepRitualViewModel {

    // MARK: - State

    enum Phase: Equatable {
        case idle
        /// 准备倒计时（3...1 → 开始）
        case countdown(Int)
        /// 正在执行某个步骤
        case running(stepIndex: Int)
        /// 用户暂停
        case paused
        /// 所有步骤完成
        case finished
        /// 提前终止
        case cancelled
    }

    private(set) var phase: Phase = .idle
    private(set) var ritual: SleepRitual?

    // MARK: - Breath State

    private(set) var breathPhase: BreathPhase = .inhale
    private(set) var breathProgress: Double = 0
    private(set) var breathScale: Double = 1.0

    enum BreathPhase: String {
        case inhale = "吸气"
        case exhale = "呼气"
    }

    // MARK: - Timers

    /// 打破 CADisplayLink → target 的强引用
    private final class DisplayLinkProxy {
        weak var owner: SleepRitualViewModel?
        init(owner: SleepRitualViewModel) { self.owner = owner }
        @objc func tick() { owner?.breathTick() }
        @objc func timerTick() { owner?.timerTick() }
    }

    private var proxy: DisplayLinkProxy?
    private var stepTimer: Timer?
    private var displayLink: CADisplayLink?
    private var breathStartDate: Date = .now
    private var currentBreathDuration: TimeInterval = 0
    private var currentStepStartDate: Date = .now
    private(set) var stepElapsed: TimeInterval = 0  // 当前步骤已过时间
    private(set) var stepDuration: TimeInterval = 0   // 当前步骤总时长


    // MARK: - Dependencies

    private let playerVM: SoundPlayerViewModel
    private let timerVM: TimerViewModel

    // MARK: - Init

    init(playerVM: SoundPlayerViewModel, timerVM: TimerViewModel) {
        self.playerVM = playerVM
        self.timerVM = timerVM
    }

    // MARK: - Actions

    func start(ritual: SleepRitual) {
        self.ritual = ritual
        phase = .countdown(3)
        startCountdown()
    }

    func skipCurrentStep() {
        guard case .running(let index) = phase,
              let ritual = ritual,
              index < ritual.steps.count
        else { return }

        finishStep(at: index)
    }

    func cancel() {
        stopAllTimers()
        playerVM.stopAll()
        timerVM.cancel()
        phase = .cancelled
    }

    // MARK: - Countdown

    private func startCountdown() {
        var count = 3
        stepTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                count -= 1
                if count <= 0 {
                    self.stepTimer?.invalidate()
                    self.phase = .running(stepIndex: 0)
                    self.beginStep(at: 0)
                } else {
                    self.phase = .countdown(count)
                }
            }
        }
        RunLoop.main.add(stepTimer!, forMode: .common)
    }

    // MARK: - Step Execution

    private func beginStep(at index: Int) {
        guard let ritual = ritual, index < ritual.steps.count else {
            finishAllSteps()
            return
        }

        let step = ritual.steps[index]
        currentStepStartDate = .now
        stepElapsed = 0

        switch step {
        case .breath(let duration):
            stepDuration = duration
            currentBreathDuration = duration
            breathStartDate = .now
            breathPhase = .inhale
            breathProgress = 0
            breathScale = 1.0
            startBreathDisplayLink()

        case .sounds(let trackIds):
            stepDuration = 3  // 音效启动很快，显示 3 秒过渡
            for trackId in trackIds {
                if let track = playerVM.tracks.first(where: { $0.id == trackId }),
                   !playerVM.activeTrackIds.contains(trackId) {
                    playerVM.toggleTrack(track)
                }
            }
            // 音效启动后立即进入下一步
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.finishStep(at: index)
            }

        case .timer(let duration):
            stepDuration = duration
            timerVM.start(duration: duration)
            startTimerDisplayLink()
        }
    }

    private func finishStep(at index: Int) {
        let nextIndex = index + 1
        stopStepTimers()

        guard let ritual = ritual, nextIndex < ritual.steps.count else {
            finishAllSteps()
            return
        }

        phase = .running(stepIndex: nextIndex)
        beginStep(at: nextIndex)
    }

    private func finishAllSteps() {
        stopAllTimers()
        phase = .finished
    }

    // MARK: - Breath Display Link

    private func startBreathDisplayLink() {
        let p = DisplayLinkProxy(owner: self)
        proxy = p
        let link = CADisplayLink(target: p, selector: #selector(DisplayLinkProxy.tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func breathTick() {
        let now = Date()
        let elapsed = now.timeIntervalSince(breathStartDate)
        let inhaleDuration: TimeInterval = 4
        let exhaleDuration: TimeInterval = 6
        let cycleDuration = inhaleDuration + exhaleDuration

        // 总时长检查
        stepElapsed = now.timeIntervalSince(currentStepStartDate)
        if stepElapsed >= currentBreathDuration {
            stopStepTimers()
            // 找当前步骤索引
            if case .running(let index) = phase {
                finishStep(at: index)
            }
            return
        }

        let cyclePosition = elapsed.truncatingRemainder(dividingBy: cycleDuration)

        if cyclePosition < inhaleDuration {
            breathPhase = .inhale
            breathProgress = cyclePosition / inhaleDuration
            breathScale = 1.0 + 0.25 * breathProgress
        } else {
            breathPhase = .exhale
            breathProgress = (cyclePosition - inhaleDuration) / exhaleDuration
            breathScale = 1.25 - 0.25 * breathProgress
        }
    }

    // MARK: - Timer Display Link

    private func startTimerDisplayLink() {
        let p = DisplayLinkProxy(owner: self)
        proxy = p
        let link = CADisplayLink(target: p, selector: #selector(DisplayLinkProxy.timerTick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: 30)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func timerTick() {
        stepElapsed = Date().timeIntervalSince(currentStepStartDate)
        if stepElapsed >= stepDuration {
            stopStepTimers()
            if case .running(let index) = phase {
                finishStep(at: index)
            }
        }
    }

    // MARK: - Cleanup

    /// 暂停内部计时/动画，但保留音效和计时器继续运行（用于视图消失时）
    func suspend() {
        stopStepTimers()
    }

    private func stopStepTimers() {
        stepTimer?.invalidate()
        stepTimer = nil
        displayLink?.invalidate()
        displayLink = nil
        proxy = nil
    }

    private func stopAllTimers() {
        stopStepTimers()
    }

    // MARK: - Formatters

    func formatRemaining() -> String {
        let remaining = max(0, stepDuration - stepElapsed)
        let m = Int(remaining) / 60
        let s = Int(remaining) % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    func currentStepName() -> String {
        guard let ritual, case .running(let index) = phase,
              index < ritual.steps.count
        else { return "" }
        return ritual.steps[index].displayName
    }

    func currentStepIcon() -> String {
        guard let ritual, case .running(let index) = phase,
              index < ritual.steps.count
        else { return "circle" }
        return ritual.steps[index].iconName
    }

    func stepProgress(at index: Int) -> Double {
        guard let ritual, index < ritual.steps.count else { return 0 }

        if case .running(let currentIndex) = phase {
            if index < currentIndex { return 1 }
            if index == currentIndex {
                return min(1, stepDuration > 0 ? stepElapsed / stepDuration : 0)
            }
            return 0
        }

        if phase == .finished { return 1 }
        return 0
    }
}
