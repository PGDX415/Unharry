//
//  SoundLibrary.swift
//  Unhurry
//

import AVFoundation
import Foundation

/// 内置音效目录。
///
/// 管理所有可用音效的元数据，并在初始化时预加载到 AudioService。
///
/// ## 音效来源
/// - **代码生成**：白噪音、粉噪音、棕噪音（零版权，永远可用）
/// - **AI 生成**：雨声、海浪、篝火（ElevenLabs 等工具生成 `.mp3` 放入 Bundle）
/// - 后续扩展：远程 URL 流式加载 + 本地缓存
final class SoundLibrary {

    // MARK: - Properties

    /// 所有可用音效的元数据列表
    let tracks: [SoundTrack]

    /// 代码生成的噪声（零版权，永远可用）
    enum GeneratedNoise: String, CaseIterable {
        case whiteNoise = "builtin_white_noise"
        case pinkNoise  = "builtin_pink_noise"
        case brownNoise = "builtin_brown_noise"

        var track: SoundTrack {
            switch self {
            case .whiteNoise:
                return SoundTrack(id: rawValue, name: "白噪音", category: .whiteNoise,
                                  fileName: rawValue, fileExtension: "caf", defaultVolume: 0.4)
            case .pinkNoise:
                return SoundTrack(id: rawValue, name: "粉噪音", category: .whiteNoise,
                                  fileName: rawValue, fileExtension: "caf", defaultVolume: 0.4)
            case .brownNoise:
                return SoundTrack(id: rawValue, name: "棕噪音", category: .whiteNoise,
                                  fileName: rawValue, fileExtension: "caf", defaultVolume: 0.35)
            }
        }
    }

    /// AI 生成的自然音（ElevenLabs 等工具生成，放入 Resources/Audio/）
    enum AINature: String, CaseIterable {
        // ── 已入库 ──
        case lightRain  = "ai_rain_light"
        case oceanCalm  = "ai_ocean_calm"
        case campfire   = "ai_fire_camp"

        // ── 新增 ──
        case windBreeze  = "ai_wind_breeze"    // 微风
        case streamFlow  = "ai_stream_flow"    // 溪流
        case thunderSlow = "ai_thunder_slow"    // 远雷
        case forestNight = "ai_forest_night"    // 夜林
        case fanHum      = "ai_fan_hum"         // 风扇

        var fileName: String { rawValue }
        var fileExtension: String { "mp3" }

        var track: SoundTrack {
            switch self {
            case .lightRain:
                return SoundTrack(id: rawValue, name: "轻雨", category: .rain,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.45)
            case .oceanCalm:
                return SoundTrack(id: rawValue, name: "海浪", category: .water,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.45)
            case .campfire:
                return SoundTrack(id: rawValue, name: "篝火", category: .nature,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.35)
            case .windBreeze:
                return SoundTrack(id: rawValue, name: "微风", category: .nature,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.3)
            case .streamFlow:
                return SoundTrack(id: rawValue, name: "溪流", category: .water,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.4)
            case .thunderSlow:
                return SoundTrack(id: rawValue, name: "远雷", category: .rain,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.35)
            case .forestNight:
                return SoundTrack(id: rawValue, name: "夜林", category: .nature,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.35)
            case .fanHum:
                return SoundTrack(id: rawValue, name: "风扇", category: .whiteNoise,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.3)
            }
        }
    }

    // MARK: - Init

    init() {
        // 合并所有音效：代码生成 + AI 自然音
        let noiseTracks = GeneratedNoise.allCases.map { $0.track }
        let aiTracks = AINature.allCases.map { $0.track }
        self.tracks = noiseTracks + aiTracks
    }

    // MARK: - Preload

    /// 预加载所有音效到 AudioService。
    ///
    /// - 代码生成的噪声：直接生成 buffer 注入
    /// - AI 自然音：从 Bundle 读取音频文件
    /// - 文件不存在时：打印 warning 但不崩溃（等待用户放入文件）
    func preloadBuiltInSounds(into audioService: AudioServiceProtocol) {
        preloadGeneratedNoise(into: audioService)
        preloadAINatureSounds(into: audioService)
    }

    // MARK: - Private: Generated Noise

    private func preloadGeneratedNoise(into audioService: AudioServiceProtocol) {
        let duration: TimeInterval = 5.0

        for item in GeneratedNoise.allCases {
            let buffer: AVAudioPCMBuffer?
            switch item {
            case .whiteNoise:  buffer = NoiseGenerator.whiteNoise(duration: duration)
            case .pinkNoise:   buffer = NoiseGenerator.pinkNoise(duration: duration)
            case .brownNoise:  buffer = NoiseGenerator.brownNoise(duration: duration)
            }
            if let buffer = buffer {
                audioService.registerBuffer(buffer, forSound: item.rawValue)
            }
        }
    }

    // MARK: - Private: AI Nature Sounds (Bundle Files)

    private func preloadAINatureSounds(into audioService: AudioServiceProtocol) {
        for item in AINature.allCases {
            let track = item.track
            // xcodegen 会将 Resources/Audio/ 下的文件平铺到 Bundle 根目录
            guard let url = Bundle.main.url(
                forResource: track.fileName,
                withExtension: track.fileExtension,
                subdirectory: nil
            ) else {
                print("""
                ⚠️  AI 音频文件缺失: \(track.fileName).\(track.fileExtension)
                   请放入 Unhurry/Resources/Audio/ 目录。
                   ElevenLabs 生成 prompt 见 CLAUDE.md 或 ElevenLabs 章节。
                """)
                continue
            }

            do {
                try audioService.loadSound(id: track.id, from: url)
                print("✅ Loaded: \(track.name) (\(track.fileName).\(track.fileExtension))")
            } catch {
                print("❌ Failed to load \(track.name): \(error)")
            }
        }
    }
}

