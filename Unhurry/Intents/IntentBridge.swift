//
//  IntentBridge.swift
//  Unhurry
//

import Foundation

/// Siri / Shortcuts Intent 与 App 内 ViewModel 之间的桥接。
///
/// App 启动时设置回调，Intent 的 `perform()` 触发回调即可驱动 ViewModel。
@MainActor
enum IntentBridge {

    /// 开始睡眠音效（无参数，启动最近使用的预设或默认音效）
    static var onStartSleep: (() -> Void)?

    /// 停止所有助眠音效
    static var onStopSounds: (() -> Void)?
}
