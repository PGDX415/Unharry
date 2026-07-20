//
//  SleepRitual.swift
//  Unhurry
//

import Foundation

// MARK: - Ritual Model

/// 入睡仪式——将呼吸、音效、计时器编排为自动化流程。
struct SleepRitual: Identifiable, Hashable, Codable {
    var id = UUID()
    let name: String
    let description: String
    let icon: String
    let steps: [RitualStep]
    var isCustom: Bool = false
}

// MARK: - Ritual Step

enum RitualStep: Hashable, Codable {
    /// 呼吸练习（引导吸气/呼气，时长秒）
    case breath(duration: TimeInterval)
    /// 启动音效组合（trackId 列表）
    case sounds(trackIds: [String])
    /// 启动睡眠计时器（倒计时秒）
    case timer(duration: TimeInterval)

    var displayName: String {
        switch self {
        case .breath:        return "呼吸放松"
        case .sounds:        return "播放音效"
        case .timer:         return "定时关闭"
        }
    }

    var iconName: String {
        switch self {
        case .breath:        return "wind"
        case .sounds:        return "speaker.wave.2.fill"
        case .timer:         return "timer"
        }
    }
}

// MARK: - Presets

extension SleepRitual {

    /// 内置仪式模板
    static let presets: [SleepRitual] = [
        SleepRitual(
            name: "快速入眠",
            description: "2 分钟呼吸 → 轻雨 + 白噪音 → 15 分钟定时",
            icon: "bed.double.fill",
            steps: [
                .breath(duration: 120),
                .sounds(trackIds: ["ai_rain_light", "builtin_white_noise"]),
                .timer(duration: 15 * 60),
            ]
        ),
        SleepRitual(
            name: "深度放松",
            description: "3 分钟呼吸 → 海浪 + 篝火 → 30 分钟定时",
            icon: "water.waves",
            steps: [
                .breath(duration: 180),
                .sounds(trackIds: ["ai_ocean_calm", "ai_fire_camp"]),
                .timer(duration: 30 * 60),
            ]
        ),
        SleepRitual(
            name: "冥想入睡",
            description: "5 分钟呼吸 → 颂钵 + 古琴 → 25 分钟定时",
            icon: "sparkles",
            steps: [
                .breath(duration: 300),
                .sounds(trackIds: ["ai_singing_bowl", "ai_guqin"]),
                .timer(duration: 25 * 60),
            ]
        ),
        SleepRitual(
            name: "林间夜宿",
            description: "2 分钟呼吸 → 夜林 + 溪流 → 20 分钟定时",
            icon: "leaf.fill",
            steps: [
                .breath(duration: 120),
                .sounds(trackIds: ["ai_forest_night", "ai_stream_flow"]),
                .timer(duration: 20 * 60),
            ]
        ),
    ]

    // MARK: - Custom Ritual Persistence

    private static let customRitualsKey = "com.unhurry.customRituals"

    /// 加载用户自定义仪式
    static func loadCustom() -> [SleepRitual] {
        guard let data = UserDefaults.standard.data(forKey: customRitualsKey),
              let rituals = try? JSONDecoder().decode([SleepRitual].self, from: data)
        else { return [] }
        return rituals
    }

    /// 保存自定义仪式
    static func saveCustom(_ rituals: [SleepRitual]) {
        if let data = try? JSONEncoder().encode(rituals) {
            UserDefaults.standard.set(data, forKey: customRitualsKey)
        }
    }

    /// 生成描述文字
    func buildDescription(trackNames: @escaping (String) -> String) -> String {
        let parts: [String] = steps.map { step in
            switch step {
            case .breath(let d):
                let m = Int(d) / 60
                return "\(m) 分钟呼吸"
            case .sounds(let ids):
                let names = ids.map { trackNames($0) }.joined(separator: "+")
                return names
            case .timer(let d):
                let m = Int(d) / 60
                return "\(m) 分钟定时"
            }
        }
        return parts.joined(separator: " → ")
    }
}
