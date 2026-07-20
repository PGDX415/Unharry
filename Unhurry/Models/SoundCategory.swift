//
//  SoundCategory.swift
//  Unhurry
//

import Foundation

/// 音效分类。
///
/// 用于界面分组展示，以及将来可能的推荐/筛选逻辑。
enum SoundCategory: String, CaseIterable, Identifiable {
    /// 雨声（轻雨、暴雨、檐下听雨等）
    case rain

    /// 水声（海浪、溪流、瀑布等）
    case water

    /// 自然（鸟鸣、风声、篝火、森林等）
    case nature

    /// 白噪音（纯白噪音、粉噪音、棕噪音）
    case whiteNoise

    /// 冥想引导
    case meditation

    /// 睡前故事
    case story

    /// AI 生成助眠音乐（八音盒、颂钵、大提琴等）
    case music

    /// 用户自定义导入的音效
    case custom

    var id: String { rawValue }

    /// 分类中文显示名
    var displayName: String {
        switch self {
        case .rain:       return "雨声"
        case .water:      return "水声"
        case .nature:     return "自然"
        case .whiteNoise: return "白噪音"
        case .meditation: return "冥想"
        case .story:      return "睡前故事"
        case .music:      return "助眠音乐"
        case .custom:     return "自定义"
        }
    }

    /// 分类图标（SF Symbol 名称）
    var iconName: String {
        switch self {
        case .rain:       return "cloud.rain.fill"
        case .water:      return "water.waves"
        case .nature:     return "leaf.fill"
        case .whiteNoise: return "waveform"
        case .meditation: return "sparkles"
        case .story:      return "book.fill"
        case .music:      return "music.note"
        case .custom:     return "square.and.arrow.down"
        }
    }
}
