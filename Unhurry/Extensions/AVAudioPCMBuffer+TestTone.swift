//
//  AVAudioPCMBuffer+TestTone.swift
//  Unhurry
//

import AVFoundation

extension AVAudioPCMBuffer {

    /// 生成一段正弦波测试音频 buffer。
    ///
    /// 用于无真实音频文件时的开发测试，验证 AudioService 的播放、混音、循环等逻辑。
    ///
    /// - Parameters:
    ///   - frequency: 频率（Hz），默认 440Hz（标准音 A4）
    ///   - duration: 时长（秒），默认 2.0
    ///   - sampleRate: 采样率，默认 44100
    ///   - amplitude: 振幅 (0.0 ~ 1.0)，默认 0.3
    /// - Returns: 单声道 Float32 PCM buffer，失败返回 nil
    static func testTone(
        frequency: Double = 440,
        duration: TimeInterval = 2.0,
        sampleRate: Double = 44100,
        amplitude: Float = 0.3
    ) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ) else {
            return nil
        }

        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else {
            return nil
        }

        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?.pointee else {
            return nil
        }

        for frame in 0..<Int(frameCount) {
            let sample = sin(2.0 * .pi * frequency * Double(frame) / sampleRate)
            channelData[frame] = Float(sample) * amplitude
        }

        return buffer
    }

    /// 生成一段静默 buffer，用于无干扰测试。
    static func silentBuffer(
        duration: TimeInterval = 2.0,
        sampleRate: Double = 44100
    ) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ) else {
            return nil
        }

        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else {
            return nil
        }

        buffer.frameLength = frameCount
        // floatChannelData 默认已初始化为零（静默）

        return buffer
    }
}
