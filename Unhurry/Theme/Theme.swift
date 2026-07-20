//
//  Theme.swift
//  Unhurry
//

import SwiftUI

/// App 主题系统——集中管理颜色，支持强调色切换和 OLED 纯黑模式。
@MainActor
enum Theme {

    // MARK: - Accent Themes

    enum Accent: String, CaseIterable {
        case gold     = "gold"
        case silver   = "silver"
        case lavender = "lavender"

        var displayName: String {
            switch self {
            case .gold:     return "暖金"
            case .silver:   return "月光银"
            case .lavender: return "薰衣草紫"
            }
        }

        var color: Color {
            switch self {
            case .gold:     return Color(red: 0.941, green: 0.902, blue: 0.824)
            case .silver:   return Color(red: 0.82, green: 0.82, blue: 0.85)
            case .lavender: return Color(red: 0.75, green: 0.65, blue: 0.90)
            }
        }

        var uiColor: UIColor {
            switch self {
            case .gold:     return UIColor(red: 0.941, green: 0.902, blue: 0.824, alpha: 1)
            case .silver:   return UIColor(red: 0.82, green: 0.82, blue: 0.85, alpha: 1)
            case .lavender: return UIColor(red: 0.75, green: 0.65, blue: 0.90, alpha: 1)
            }
        }
    }

    // MARK: - UserDefaults Keys

    private static let defaults = UserDefaults.standard

    private static let keyAccentTheme = "accentTheme"
    private static let keyBlackBg = "useBlackBackground"
    private static let keyDefaultVolume = "defaultVolume"
    private static let keyBufferDuration = "bufferDuration"

    // MARK: - Current Theme State

    static var accentThemeRaw: String {
        get { defaults.string(forKey: keyAccentTheme) ?? Accent.gold.rawValue }
        set { defaults.set(newValue, forKey: keyAccentTheme) }
    }

    static var useBlackBackground: Bool {
        get { defaults.bool(forKey: keyBlackBg) }
        set { defaults.set(newValue, forKey: keyBlackBg) }
    }

    static var accent: Accent {
        Accent(rawValue: accentThemeRaw) ?? .gold
    }

    // MARK: - Computed Colors

    /// 强调色（文字、图标）
    static var accentColor: Color { accent.color }

    /// 背景色
    static var bgColor: Color {
        useBlackBackground
            ? Color(red: 0.05, green: 0.05, blue: 0.05)  // 纯黑 OLED
            : Color(red: 0.216, green: 0.184, blue: 0.322) // 暮色紫
    }

    /// UIKit 背景色（用于富文本等场景）
    static var bgUIColor: UIColor {
        useBlackBackground
            ? UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
            : UIColor(red: 0.216, green: 0.184, blue: 0.322, alpha: 1)
    }

    // MARK: - Default Volume / Buffer

    static var defaultVolume: Double {
        get {
            let v = defaults.double(forKey: keyDefaultVolume)
            return v > 0 ? v : 0.5  // 首次启动时 double 默认返回 0
        }
        set { defaults.set(newValue, forKey: keyDefaultVolume) }
    }

    static var bufferDuration: Double {
        get {
            let v = defaults.double(forKey: keyBufferDuration)
            return v > 0 ? v : 3.0
        }
        set { defaults.set(newValue, forKey: keyBufferDuration) }
    }

    /// 可用缓冲时长选项
    static let bufferOptions: [(String, TimeInterval)] = [
        ("即时播放", 0),
        ("3 秒", 3),
        ("5 秒", 5),
    ]

    // MARK: - Health

    private static let keyHealthSync = "healthSyncEnabled"

    static var healthSyncEnabled: Bool {
        get { defaults.object(forKey: keyHealthSync) as? Bool ?? true }  // 默认开启
        set { defaults.set(newValue, forKey: keyHealthSync) }
    }

    // MARK: - Bedtime Reminder

    private static let keyReminderEnabled = "reminderEnabled"
    private static let keyReminderHour = "reminderHour"
    private static let keyReminderMinute = "reminderMinute"
    private static let keyReminderPresetId = "reminderPresetId"

    static var reminderEnabled: Bool {
        get { defaults.bool(forKey: keyReminderEnabled) }
        set { defaults.set(newValue, forKey: keyReminderEnabled) }
    }

    static var reminderHour: Int {
        get { defaults.integer(forKey: keyReminderHour) }
        set { defaults.set(newValue, forKey: keyReminderHour) }
    }

    static var reminderMinute: Int {
        get { defaults.integer(forKey: keyReminderMinute) }
        set { defaults.set(newValue, forKey: keyReminderMinute) }
    }

    static var reminderPresetId: String? {
        get { defaults.string(forKey: keyReminderPresetId) }
        set { defaults.set(newValue, forKey: keyReminderPresetId) }
    }

    /// 就寝提醒的 Date 表示（今天的时间分量）
    static var reminderDate: Date {
        var comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        comps.hour = reminderHour == 0 && reminderMinute == 0 ? 22 : reminderHour
        comps.minute = reminderMinute
        return Calendar.current.date(from: comps) ?? Date()
    }
}
