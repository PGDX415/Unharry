//
//  AudioServiceProtocol.swift
//  Unhurry
//

import AVFoundation

// MARK: - Audio Service Errors

enum AudioServiceError: LocalizedError {
    case soundNotLoaded(String)
    case bufferAllocationFailed
    case engineStartFailed(Error)
    case sessionActivationFailed(Error)
    case soundAlreadyPlaying(String)

    var errorDescription: String? {
        switch self {
        case .soundNotLoaded(let id):
            return "Sound '\(id)' is not loaded."
        case .bufferAllocationFailed:
            return "Failed to allocate audio buffer."
        case .engineStartFailed(let error):
            return "Failed to start audio engine: \(error.localizedDescription)"
        case .sessionActivationFailed(let error):
            return "Failed to activate audio session: \(error.localizedDescription)"
        case .soundAlreadyPlaying(let id):
            return "Sound '\(id)' is already playing."
        }
    }
}

// MARK: - Audio Service Protocol

/// 音频播放服务的抽象接口。
///
/// 定义协议以便于单元测试 mock 和将来可能的实现替换。
protocol AudioServiceProtocol: AnyObject {

    // MARK: - Engine State

    /// 音频引擎是否正在运行
    var isEngineRunning: Bool { get }

    /// 当前正在播放的音效 ID 列表
    var activeSoundIds: [String] { get }

    /// 主混音器节点（供可视化等外部 tap 使用）
    var mainMixerNode: AVAudioMixerNode { get }

    // MARK: - Sound Loading

    /// 加载音频文件到内存 buffer。
    /// - Parameters:
    ///   - id: 音效唯一标识
    ///   - url: 音频文件 URL
    func loadSound(id: String, from url: URL) throws

    /// 直接注册 PCM buffer（跳过文件加载，用于测试）。
    /// - Parameters:
    ///   - buffer: 音频 PCM buffer
    ///   - id: 音效唯一标识
    func registerBuffer(_ buffer: AVAudioPCMBuffer, forSound id: String)

    /// 移除已加载的音效
    func unloadSound(id: String)

    // MARK: - Playback Control

    /// 播放音效。
    /// - Parameters:
    ///   - soundId: 已加载的音效 ID
    ///   - volume: 初始音量 (0.0 ~ 1.0)
    ///   - loop: 是否循环播放
    func play(soundId: String, volume: Float, loop: Bool) throws

    /// 停止播放指定音效并释放其播放节点。
    func stop(soundId: String)

    /// 暂停指定音效（保留节点，可恢复）。
    func pause(soundId: String)

    /// 恢复暂停的音效。
    func resume(soundId: String) throws

    /// 停止所有正在播放的音效。
    func stopAll()

    // MARK: - Volume Control

    /// 设置指定音效的音量（即时生效）。
    func setVolume(_ volume: Float, for soundId: String)

    // MARK: - Fade Effects

    /// 淡入：在指定时长内从当前音量渐变到目标音量。
    func fadeIn(soundId: String, duration: TimeInterval, targetVolume: Float)

    /// 淡出：在指定时长内从当前音量渐变到 0，完成后自动停止并释放节点。
    func fadeOut(soundId: String, duration: TimeInterval, completion: (() -> Void)?)

    // MARK: - EQ & Reverb

    /// 设置指定音效的低音/高音增益（dB）。
    /// - Parameters:
    ///   - soundId: 音效 ID
    ///   - bassGain: 低音增益，-12...+12 dB
    ///   - trebleGain: 高音增益，-12...+12 dB
    func setEQ(for soundId: String, bassGain: Float, trebleGain: Float)

    /// 设置指定音效的混响（reverb）湿/干比。
    /// - Parameters:
    ///   - soundId: 音效 ID
    ///   - wetDryMix: 0 = 纯干声，100 = 纯湿声
    func setReverb(for soundId: String, wetDryMix: Float)

    // MARK: - Crossfade

    /// 交叉淡入淡出：在指定时长内把 fromId 淡出，同时把 toId 淡入。
    /// 完成后自动停止 fromId。
    func crossfade(from fromId: String, to toId: String, duration: TimeInterval, completion: (() -> Void)?)

    // MARK: - Engine Lifecycle

    /// 启动音频引擎并激活 audio session。
    func startEngine() throws

    /// 停止音频引擎并停用 audio session。
    func stopEngine()
}
