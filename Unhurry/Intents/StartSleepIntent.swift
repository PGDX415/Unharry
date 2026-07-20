//
//  StartSleepIntent.swift
//  Unhurry
//

import AppIntents

/// "开始睡眠音效" — 启动最近使用的预设，或默认混音组合。
///
/// Siri 触发短语示例：
/// - "嘿 Siri，开始睡眠音效"
/// - "Hey Siri, start sleep sounds with 闲眠"
///
/// 也可在「快捷指令」App 中手动创建自动化。
struct StartSleepIntent: AppIntent {

    static let title: LocalizedStringResource = "开始睡眠音效"
    static let description = IntentDescription(
        "启动助眠音效，自动恢复最近使用的混音组合",
        categoryName: "睡眠"
    )

    /// 需要 App 进入前台才能驱动 AVAudioEngine 播放
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentBridge.onStartSleep?()
        return .result()
    }
}
