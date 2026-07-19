//
//  AudioTestHelpers.swift
//  UnhurryTests
//

import AVFoundation
@testable import Unhurry

/// 音频测试辅助工具。
enum AudioTestHelpers {

    /// 创建临时的 .wav 音频文件，内容为指定频率的正弦波。
    ///
    /// 生成的文件存储在 NSTemporaryDirectory()，返回 URL。
    /// 测试完成后应手动删除。
    ///
    /// - Parameters:
    ///   - frequency: 频率（Hz）
    ///   - duration: 时长（秒）
    ///   - sampleRate: 采样率
    /// - Returns: 临时文件 URL
    static func createTempAudioFile(
        frequency: Double = 440,
        duration: TimeInterval = 2.0,
        sampleRate: Double = 44100
    ) throws -> URL {
        guard let buffer = AVAudioPCMBuffer.testTone(
            frequency: frequency,
            duration: duration,
            sampleRate: sampleRate
        ) else {
            throw NSError(domain: "AudioTestHelpers", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create test tone buffer"])
        }

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("unhurry_test_\(UUID().uuidString).wav")

        guard let format = buffer.format as AVAudioFormat? else {
            throw NSError(domain: "AudioTestHelpers", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid audio format"])
        }

        let file = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        try file.write(from: buffer)
        return tempURL
    }

    /// 删除临时音频文件。
    static func removeTempFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
