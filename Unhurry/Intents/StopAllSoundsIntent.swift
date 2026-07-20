//
//  StopAllSoundsIntent.swift
//  Unhurry
//

import AppIntents

/// "停止助眠音效" — 停止所有正在播放的音效和故事。
///
/// Siri 触发短语示例：
/// - "嘿 Siri，停止助眠音效"
/// - "Hey Siri, stop sleep sounds with 闲眠"
struct StopAllSoundsIntent: AppIntent {

    static let title: LocalizedStringResource = "停止助眠音效"
    static let description = IntentDescription(
        "停止所有正在播放的助眠音效与睡前故事",
        categoryName: "睡眠"
    )

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentBridge.onStopSounds?()
        return .result()
    }
}
