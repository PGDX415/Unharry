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
    private(set) var tracks: [SoundTrack]

    /// 自定义音效存储目录
    private static var customAudioDir: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CustomAudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static let customTracksKey = "com.unhurry.customTracks"

    /// 可持久化的自定义音效元数据
    private struct CustomTrackMeta: Codable {
        let id: String
        let name: String
        let fileExtension: String
    }

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
        case windBreeze   = "ai_wind_breeze"     // 微风
        case streamFlow   = "ai_stream_flow"     // 溪流
        case thunderSlow  = "ai_thunder_slow"     // 远雷
        case forestNight  = "ai_forest_night"     // 夜林
        case fanHum       = "ai_fan_hum"          // 风扇
        case roofRain     = "ai_roof_rain"        // 屋檐听雨
        case carRain      = "ai_car_rain"         // 雨打车窗
        case waterfall    = "ai_waterfall"         // 瀑布
        case summerBugs   = "ai_summer_bugs"       // 夏夜虫鸣
        case bambooWind   = "ai_bamboo_wind"       // 风吹竹林
        case guqin        = "ai_guqin"             // 古琴
        case heartbeat    = "ai_heartbeat"          // 心跳

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
            case .roofRain:
                return SoundTrack(id: rawValue, name: "屋檐听雨", category: .rain,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.45)
            case .carRain:
                return SoundTrack(id: rawValue, name: "雨打车窗", category: .rain,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.4)
            case .waterfall:
                return SoundTrack(id: rawValue, name: "瀑布", category: .water,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.4)
            case .summerBugs:
                return SoundTrack(id: rawValue, name: "夏夜虫鸣", category: .nature,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.3)
            case .bambooWind:
                return SoundTrack(id: rawValue, name: "风吹竹林", category: .nature,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.35)
            case .guqin:
                return SoundTrack(id: rawValue, name: "古琴", category: .meditation,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.4)
            case .heartbeat:
                return SoundTrack(id: rawValue, name: "心跳", category: .whiteNoise,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.25)
            }
        }
    }

    /// AI 生成助眠音乐（八音盒、颂钵、大提琴等）
    enum AIMusic: String, CaseIterable {
        case musicBox        = "ai_music_box"          // 八音盒
        case singingBowl     = "ai_singing_bowl"       // 颂钵疗愈
        case celloNocturne   = "ai_cello_nocturne"     // 大提琴夜曲
        case underwaterPiano = "ai_underwater_piano"   // 水中钢琴
        case deepSpace       = "ai_deep_space"         // 深空漫游

        var fileName: String { rawValue }
        var fileExtension: String { "mp3" }

        var track: SoundTrack {
            switch self {
            case .musicBox:
                return SoundTrack(id: rawValue, name: "八音盒", category: .music,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.25)
            case .singingBowl:
                return SoundTrack(id: rawValue, name: "颂钵疗愈", category: .music,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.35)
            case .celloNocturne:
                return SoundTrack(id: rawValue, name: "大提琴夜曲", category: .music,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.35)
            case .underwaterPiano:
                return SoundTrack(id: rawValue, name: "水中钢琴", category: .music,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.3)
            case .deepSpace:
                return SoundTrack(id: rawValue, name: "深空漫游", category: .music,
                                  fileName: fileName, fileExtension: fileExtension, defaultVolume: 0.3)
            }
        }
    }

    // MARK: - Init

    init() {
        // 内置音效：代码生成 + AI 自然音 + AI 音乐
        let noiseTracks = GeneratedNoise.allCases.map { $0.track }
        let aiNatureTracks = AINature.allCases.map { $0.track }
        let aiMusicTracks = AIMusic.allCases.map { $0.track }
        let builtIn = noiseTracks + aiNatureTracks + aiMusicTracks

        // 用户自定义音效
        let customTracks = Self.loadCustomTracks()

        self.tracks = builtIn + customTracks
    }

    // MARK: - Custom Tracks

    /// 导入用户自定义音效。
    /// - Parameters:
    ///   - sourceURL: 用户选择的文件 URL（来自 document picker）
    ///   - audioService: 用于加载音频
    /// - Returns: 导入成功返回 SoundTrack，失败返回 nil
    func importCustomTrack(from sourceURL: URL, into audioService: AudioServiceProtocol) -> SoundTrack? {
        let ext = sourceURL.pathExtension.lowercased()
        let id = "custom_\(UUID().uuidString)"
        let name = sourceURL.deletingPathExtension().lastPathComponent
        let destURL = Self.customAudioDir.appendingPathComponent("\(id).\(ext)")

        // 复制文件到 App 沙盒
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            print("⚠️ Failed to copy custom audio: \(error)")
            return nil
        }

        // 加载到 AudioService
        do {
            try audioService.loadSound(id: id, from: destURL)
        } catch {
            print("⚠️ Failed to load custom audio: \(error)")
            try? FileManager.default.removeItem(at: destURL)
            return nil
        }

        let track = SoundTrack(
            id: id,
            name: name,
            category: .custom,
            fileName: id,
            fileExtension: ext,
            defaultVolume: 0.4,
            isLoopable: true,
            localFileURL: destURL
        )

        tracks.append(track)
        persistCustomTracks()
        return track
    }

    /// 删除用户自定义音效。
    func deleteCustomTrack(_ trackId: String) {
        guard let track = tracks.first(where: { $0.id == trackId }),
              track.category == .custom else { return }

        // 删除文件
        if let url = track.localFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        // 从 AudioService 卸载
        // (AudioService 没有公开的 unload，由 ViewModel 在调用前 stopTrack 处理)

        tracks.removeAll { $0.id == trackId }
        persistCustomTracks()
    }

    /// 重新加载自定义音效到 AudioService（App 启动时调用）。
    func preloadCustomTracks(into audioService: AudioServiceProtocol) {
        for track in tracks where track.category == .custom {
            guard let url = track.localFileURL else { continue }
            do {
                try audioService.loadSound(id: track.id, from: url)
            } catch {
                print("⚠️ Failed to reload custom track \(track.name): \(error)")
            }
        }
    }

    // MARK: - Persistence

    private func persistCustomTracks() {
        let customTracks = tracks
            .filter { $0.category == .custom }
            .map { CustomTrackMeta(id: $0.id, name: $0.name, fileExtension: $0.fileExtension) }
        if let data = try? JSONEncoder().encode(customTracks) {
            UserDefaults.standard.set(data, forKey: Self.customTracksKey)
        }
    }

    private static func loadCustomTracks() -> [SoundTrack] {
        guard let data = UserDefaults.standard.data(forKey: customTracksKey),
              let metas = try? JSONDecoder().decode([CustomTrackMeta].self, from: data)
        else { return [] }

        return metas.compactMap { meta in
            let url = customAudioDir.appendingPathComponent("\(meta.id).\(meta.fileExtension)")
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return SoundTrack(
                id: meta.id,
                name: meta.name,
                category: .custom,
                fileName: meta.id,
                fileExtension: meta.fileExtension,
                defaultVolume: 0.4,
                isLoopable: true,
                localFileURL: url
            )
        }
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
        preloadAIMusic(into: audioService)
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

    // MARK: - Private: AI Music (Bundle Files)

    private func preloadAIMusic(into audioService: AudioServiceProtocol) {
        for item in AIMusic.allCases {
            let track = item.track
            guard let url = Bundle.main.url(
                forResource: track.fileName,
                withExtension: track.fileExtension,
                subdirectory: nil
            ) else {
                print("""
                ⚠️  AI 音乐文件缺失: \(track.fileName).\(track.fileExtension)
                   请放入 Unhurry/Resources/Audio/ 目录。
                   参考 prompt：
                   八音盒 → slow music box lullaby, soft crystal tone, gentle looping melody
                   颂钵 → Tibetan singing bowl resonance, single note long sustain, healing frequency
                   大提琴 → slow cello nocturne, deep warm long bow strokes, minimal melody
                   水中钢琴 → underwater muffled piano, slow sparse notes, bubbling ambience
                   深空 → slow evolving ambient drone, deep sub-bass, weightless floating
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

