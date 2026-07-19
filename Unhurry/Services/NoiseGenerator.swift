//
//  NoiseGenerator.swift
//  Unhurry
//

import AVFoundation

/// 纯算法噪声生成器。
///
/// 零版权风险的白噪音、粉噪音、棕噪音生成，用于：
/// - 种子音频：2-3 个占位音效，验证 AudioService 管线
/// - 长期方案：作为内置音效之一，不依赖外部音频文件
///
/// ## 算法来源
/// - 白噪音：均匀分布随机数
/// - 粉噪音：Voss-McCartney 算法（多速率随机生成器叠加）
/// - 棕噪音（Brownian noise）：白噪音累积积分
enum NoiseGenerator {

    // MARK: - White Noise

    /// 生成白噪音 buffer（均匀分布随机采样）。
    static func whiteNoise(
        duration: TimeInterval,
        sampleRate: Double = 44100,
        amplitude: Float = 0.3
    ) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ) else { return nil }

        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channelData = buffer.floatChannelData?.pointee
        else { return nil }

        buffer.frameLength = frameCount
        for i in 0..<Int(frameCount) {
            channelData[i] = Float.random(in: -1...1) * amplitude
        }
        return buffer
    }

    // MARK: - Pink Noise（Voss-McCartney 算法）

    /// 生成粉噪音 buffer（1/f 频谱）。
    ///
    /// 使用 Voss-McCartney 算法：维护 16 个独立白噪音生成器，
    /// 每个以不同频率（2^j 样本周期）更新，叠加后归一化。
    static func pinkNoise(
        duration: TimeInterval,
        sampleRate: Double = 44100,
        amplitude: Float = 0.3,
        generatorCount: Int = 16
    ) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ) else { return nil }

        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channelData = buffer.floatChannelData?.pointee
        else { return nil }

        buffer.frameLength = frameCount

        // Voss 算法：每个 generator 以 2^j 周期更新
        var generators = [Float](repeating: 0, count: generatorCount)
        for i in 0..<Int(frameCount) {
            for j in 0..<generatorCount {
                // 当 frame 索引是该 generator 周期的整数倍时更新
                if i % (1 << j) == 0 {
                    generators[j] = Float.random(in: -1...1)
                }
            }
            let sum = generators.reduce(0, +)
            channelData[i] = (sum / Float(generatorCount)) * amplitude
        }
        return buffer
    }

    // MARK: - Brown Noise（Brownian / Red Noise）

    /// 生成棕噪音 buffer（1/f² 频谱）。
    ///
    /// 对白噪音做累积积分（每次采样加上一个小的随机偏移），
    /// 同时在接近限幅时加入偏置防止漂移。
    static func brownNoise(
        duration: TimeInterval,
        sampleRate: Double = 44100,
        amplitude: Float = 0.3
    ) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ) else { return nil }

        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channelData = buffer.floatChannelData?.pointee
        else { return nil }

        buffer.frameLength = frameCount

        var value: Float = 0
        for i in 0..<Int(frameCount) {
            // 每次叠加一个小的随机步长
            value += Float.random(in: -0.02...0.02)
            // 加入阻尼，防止漂移到极值
            value *= 0.999
            // 硬限幅
            value = max(-1, min(1, value))
            channelData[i] = value * amplitude
        }
        return buffer
    }

    // MARK: - File I/O

    /// 将 PCM buffer 保存为 `.caf` 音频文件。
    ///
    /// `.caf`（Core Audio Format）是 Apple 原生容器格式，
    /// 支持 PCM 无损存储且无时长限制。
    static func saveToFile(
        buffer: AVAudioPCMBuffer,
        url: URL
    ) throws {
        guard let format = buffer.format as AVAudioFormat? else {
            throw NSError(domain: "NoiseGenerator", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid audio format"])
        }

        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
    }
}
