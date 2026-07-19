//
//  SoundLibrary.swift
//  Unhurry
//

import AVFoundation
import Foundation

/// 内置音效目录。
///
/// 管理所有可用音效的元数据，并在初始化时将「种子音频」预加载到 AudioService。
///
/// ## 当前状态
/// - 包含 3 种代码生成的噪声（白噪音、粉噪音、棕噪音）作为种子音频
/// - 后续 Phase：替换为 AI 生成的自然音（雨声、海浪等），
///   并扩展为从 Bundle 或远端加载的完整音效库
final class SoundLibrary {

    // MARK: - Properties

    /// 所有可用音效的元数据列表
    let tracks: [SoundTrack]

    /// 种子音频（代码生成，零版权）
    enum BuiltIn: String, CaseIterable {
        case whiteNoise  = "builtin_white_noise"
        case pinkNoise   = "builtin_pink_noise"
        case brownNoise  = "builtin_brown_noise"

        var track: SoundTrack {
            switch self {
            case .whiteNoise:
                return SoundTrack(
                    id: rawValue,
                    name: "白噪音",
                    category: .whiteNoise,
                    fileName: rawValue,
                    fileExtension: "caf",
                    defaultVolume: 0.4
                )
            case .pinkNoise:
                return SoundTrack(
                    id: rawValue,
                    name: "粉噪音",
                    category: .whiteNoise,
                    fileName: rawValue,
                    fileExtension: "caf",
                    defaultVolume: 0.4
                )
            case .brownNoise:
                return SoundTrack(
                    id: rawValue,
                    name: "棕噪音",
                    category: .whiteNoise,
                    fileName: rawValue,
                    fileExtension: "caf",
                    defaultVolume: 0.35
                )
            }
        }
    }

    // MARK: - Init

    /// 初始化音效库。
    ///
    /// 当前阶段：将所有 `BuiltIn` 种子音频通过代码生成注册到 `AudioService`，
    /// 后续可扩展为从 Bundle 文件或远程 URL 加载。
    init() {
        self.tracks = BuiltIn.allCases.map { $0.track }
    }

    // MARK: - Preload

    /// 将种子音频生成并注册到 AudioService。
    ///
    /// 在 App 启动时调用一次。生成 5 秒的循环噪声 buffer，
    /// 直接注入 AudioService 而非走文件 I/O。
    /// - Parameter audioService: 目标音频服务
    func preloadBuiltInSounds(into audioService: AudioServiceProtocol) {
        let duration: TimeInterval = 5.0  // 5 秒循环 buffer

        for builtin in BuiltIn.allCases {
            let buffer: AVAudioPCMBuffer?
            switch builtin {
            case .whiteNoise:
                buffer = NoiseGenerator.whiteNoise(duration: duration)
            case .pinkNoise:
                buffer = NoiseGenerator.pinkNoise(duration: duration)
            case .brownNoise:
                buffer = NoiseGenerator.brownNoise(duration: duration)
            }

            if let buffer = buffer {
                audioService.registerBuffer(buffer, forSound: builtin.rawValue)
            }
        }
    }
}
