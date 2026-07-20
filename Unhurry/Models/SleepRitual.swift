//
//  SleepRitual.swift
//  Unhurry
//

import Foundation

// MARK: - Ritual Model

/// 入睡仪式——将呼吸、音效、计时器编排为自动化流程。
struct SleepRitual: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let steps: [RitualStep]
}

// MARK: - Ritual Step

enum RitualStep: Hashable {
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
}
