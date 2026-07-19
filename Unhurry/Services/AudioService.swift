//
//  AudioService.swift
//  Unhurry
//

import AVFoundation

/// 基于 `AVAudioEngine` 的音频播放服务。
///
/// ## 架构设计
///
/// ### 混音拓扑
/// ```
/// AVAudioEngine
///   ├── mainMixerNode ──→ outputNode ──→ 硬件输出
///   ├── playerNode[rain]  ──→ mainMixerNode
///   ├── playerNode[ocean] ──→ mainMixerNode
///   └── playerNode[fire]  ──→ mainMixerNode
/// ```
///
/// **关键决策：**
/// - **每个音效 = 一个独立的 `AVAudioPlayerNode`**：
///   每个并发播放的音效拥有自己的 player node，直接连接到 engine 的
///   `mainMixerNode`。这保证了每个音轨的独立音量控制和淡入淡出，
///   不需要自定义 mixer 层级（引擎自带主 mixer 足够处理混音）。
///
/// - **Buffer 预加载**：音频文件在 `loadSound` 时读入
///   `AVAudioPCMBuffer` 并缓存。播放时直接从缓存取 buffer 调度，
///   避免重复 I/O。白噪音/自然音这类需要循环播放的 buffer 使用
///   `.loops` 选项实现无缝循环，无需 completion handler 手动重调度。
///
/// - **淡入淡出**：通过 `Timer` 以 ~20Hz 的步进频率调整 player 的
///   `volume` 属性。淡出完成后自动停止 player 并断开连接，释放资源。
///
/// - **线程安全**：所有状态变更（buffer 字典、player 字典、fade timer
///   字典）通过串行 `DispatchQueue` 同步。Engine 操作（attach、connect、
///   disconnect）在同一队列执行以确保线程一致性。
///
/// - **后台播放**：通过 `AudioSessionManager` 配置 `.playback` category，
///   配合 Info.plist 的 `UIBackgroundModes: audio` 声明。
///
/// - **中断处理**：`AudioSessionManager` 监听 `AVAudioSession` 中断通知
///   （如来电），`AudioService` 在中断开始时暂停所有播放，中断结束后
///   根据 `shouldResume` 标志决定是否恢复。
final class AudioService: AudioServiceProtocol, @unchecked Sendable {

    // MARK: - Private Properties

    private let engine: AVAudioEngine
    private let mainMixer: AVAudioMixerNode
    private let sessionManager: AudioSessionManager

    /// 已加载的音频 buffer 缓存。key = soundId
    private var loadedBuffers: [String: AVAudioPCMBuffer] = [:]

    /// 活跃的 player node。key = soundId
    private var activePlayers: [String: AVAudioPlayerNode] = [:]

    /// 淡入淡出计时器。key = soundId
    private var fadeTimers: [String: Timer] = [:]

    /// 序列化所有状态操作的队列
    private let queue = DispatchQueue(label: "com.unhurry.audioservice")

    /// 淡入淡出的步进间隔（秒），≈20 steps/sec 保证平滑
    private static let fadeStepInterval: TimeInterval = 0.05

    // MARK: - Public Properties

    private(set) var isEngineRunning: Bool = false

    var activeSoundIds: [String] {
        queue.sync { Array(activePlayers.keys) }
    }

    // MARK: - Init

    init(
        engine: AVAudioEngine = AVAudioEngine(),
        sessionManager: AudioSessionManager = AudioSessionManager()
    ) {
        self.engine = engine
        self.mainMixer = engine.mainMixerNode
        self.sessionManager = sessionManager
        setupInterruptionHandling()
    }

    // MARK: - Sound Loading

    func loadSound(id: String, from url: URL) throws {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let capacity = AVAudioFrameCount(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            throw AudioServiceError.bufferAllocationFailed
        }

        try file.read(into: buffer)

        queue.sync {
            loadedBuffers[id] = buffer
        }
    }

    func registerBuffer(_ buffer: AVAudioPCMBuffer, forSound id: String) {
        queue.sync {
            loadedBuffers[id] = buffer
        }
    }

    func unloadSound(id: String) {
        queue.sync {
            // 如果正在播放，先停止
            if let player = activePlayers[id] {
                fadeTimers[id]?.invalidate()
                fadeTimers.removeValue(forKey: id)
                player.stop()
                engine.disconnectNodeOutput(player)
                activePlayers.removeValue(forKey: id)
            }
            loadedBuffers.removeValue(forKey: id)
        }
    }

    // MARK: - Playback Control

    func play(soundId: String, volume: Float, loop: Bool) throws {
        let buffer: AVAudioPCMBuffer = try queue.sync {
            guard let buf = loadedBuffers[soundId] else {
                throw AudioServiceError.soundNotLoaded(soundId)
            }

            // 如果已存在同 ID 的 player，先清理
            if let existing = activePlayers[soundId] {
                fadeTimers[soundId]?.invalidate()
                fadeTimers.removeValue(forKey: soundId)
                existing.stop()
                engine.disconnectNodeOutput(existing)
                activePlayers.removeValue(forKey: soundId)
            }

            // 创建新 player node，挂载并连接
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mainMixer, format: buf.format)
            player.volume = max(0, min(1, volume))

            activePlayers[soundId] = player
            return buf
        }

        // 确保 engine 在运行
        if !engine.isRunning {
            try startEngine()
        }

        // 调度 buffer
        queue.sync {
            guard let player = activePlayers[soundId] else { return }

            if loop {
                player.scheduleBuffer(buffer, at: nil, options: .loops)
            } else {
                player.scheduleBuffer(buffer, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                    // 非循环播放完成后自动清理
                    self?.queue.async {
                        self?.cleanupPlayer(for: soundId)
                    }
                }
            }

            player.play()
        }
    }

    func stop(soundId: String) {
        queue.sync {
            cleanupPlayer(for: soundId)
        }
    }

    func pause(soundId: String) {
        queue.sync {
            activePlayers[soundId]?.pause()
        }
    }

    func resume(soundId: String) throws {
        if !engine.isRunning {
            try startEngine()
        }
        queue.sync {
            activePlayers[soundId]?.play()
        }
    }

    func stopAll() {
        queue.sync {
            let ids = Array(activePlayers.keys)
            for id in ids {
                cleanupPlayer(for: id)
            }
        }
    }

    // MARK: - Volume Control

    func setVolume(_ volume: Float, for soundId: String) {
        let clamped = max(0, min(1, volume))
        queue.sync {
            activePlayers[soundId]?.volume = clamped
        }
    }

    // MARK: - Fade Effects

    func fadeIn(soundId: String, duration: TimeInterval, targetVolume: Float) {
        let clampedTarget = max(0, min(1, targetVolume))
        let steps = max(1, Int(duration / Self.fadeStepInterval))

        queue.async { [weak self] in
            guard let self = self, let player = self.activePlayers[soundId] else { return }

            let startVolume = player.volume
            self.fadeTimers[soundId]?.invalidate()
            var currentStep = 0

            // Timer 必须在有 run loop 的线程上创建
            DispatchQueue.main.async {
                let timer = Timer.scheduledTimer(
                    withTimeInterval: Self.fadeStepInterval,
                    repeats: true
                ) { [weak self] timer in
                    guard let self = self else {
                        timer.invalidate()
                        return
                    }
                    currentStep += 1
                    if currentStep >= steps {
                        timer.invalidate()
                        self.queue.async {
                            self.activePlayers[soundId]?.volume = clampedTarget
                            self.fadeTimers.removeValue(forKey: soundId)
                        }
                    } else {
                        let progress = Float(currentStep) / Float(steps)
                        let newVolume = startVolume + (clampedTarget - startVolume) * progress
                        self.queue.async {
                            self.activePlayers[soundId]?.volume = max(0, min(1, newVolume))
                        }
                    }
                }

                // 确保 timer 在 common modes 下也能触发（例如滚动时）
                RunLoop.main.add(timer, forMode: .common)
                self.fadeTimers[soundId] = timer
            }
        }
    }

    func fadeOut(soundId: String, duration: TimeInterval, completion: (() -> Void)?) {
        let steps = max(1, Int(duration / Self.fadeStepInterval))

        queue.async { [weak self] in
            guard let self = self, let player = self.activePlayers[soundId] else {
                DispatchQueue.main.async { completion?() }
                return
            }

            let startVolume = player.volume
            self.fadeTimers[soundId]?.invalidate()
            var currentStep = 0

            DispatchQueue.main.async {
                let timer = Timer.scheduledTimer(
                    withTimeInterval: Self.fadeStepInterval,
                    repeats: true
                ) { [weak self] timer in
                    guard let self = self else {
                        timer.invalidate()
                        return
                    }
                    currentStep += 1
                    if currentStep >= steps {
                        timer.invalidate()
                        self.queue.async { [weak self] in
                            guard let self = self else { return }
                            self.cleanupPlayer(for: soundId)
                            self.fadeTimers.removeValue(forKey: soundId)
                            DispatchQueue.main.async { completion?() }
                        }
                    } else {
                        let progress = Float(currentStep) / Float(steps)
                        let newVolume = startVolume * (1.0 - progress)
                        self.queue.async {
                            self.activePlayers[soundId]?.volume = max(0, newVolume)
                        }
                    }
                }

                RunLoop.main.add(timer, forMode: .common)
                self.fadeTimers[soundId] = timer
            }
        }
    }

    // MARK: - Engine Lifecycle

    func startEngine() throws {
        // 激活 audio session
        do {
            try sessionManager.activate()
        } catch {
            throw AudioServiceError.sessionActivationFailed(error)
        }

        // 启动引擎
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            // 引擎启动失败时回滚 session
            try? sessionManager.deactivate()
            throw AudioServiceError.engineStartFailed(error)
        }
    }

    func stopEngine() {
        stopAll()
        engine.stop()
        isEngineRunning = false
        try? sessionManager.deactivate()
    }

    // MARK: - Private Helpers

    /// 清理指定 soundId 的 player 节点及相关资源。
    /// 必须在 `queue` 上调用。
    private func cleanupPlayer(for soundId: String) {
        fadeTimers[soundId]?.invalidate()
        fadeTimers.removeValue(forKey: soundId)

        if let player = activePlayers[soundId] {
            player.stop()
            engine.disconnectNodeOutput(player)
            // 注意：不调用 engine.detach()，因为 detach 会导致已连接的
            // 其他节点重新配置。disconnectNodeOutput 足以阻止其发声。
        }

        activePlayers.removeValue(forKey: soundId)
    }

    /// 设置音频中断处理。
    private func setupInterruptionHandling() {
        sessionManager.interruptionHandler = { [weak self] interruption in
            guard let self = self else { return }
            switch interruption {
            case .began:
                // 中断开始：暂停所有活跃 player
                self.queue.sync {
                    for (_, player) in self.activePlayers {
                        player.pause()
                    }
                }
                self.isEngineRunning = false

            case .ended(let shouldResume):
                if shouldResume {
                    // 中断结束且应恢复
                    self.queue.async {
                        do {
                            try self.sessionManager.activate()
                            try self.engine.start()
                            self.isEngineRunning = true
                            for (_, player) in self.activePlayers {
                                player.play()
                            }
                        } catch {
                            // 恢复失败，静默处理；
                            // 用户可手动重新播放
                        }
                    }
                }
            }
        }
    }
}
