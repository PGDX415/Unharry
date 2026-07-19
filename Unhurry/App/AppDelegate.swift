//
//  AppDelegate.swift
//  Unhurry
//

import UIKit

/// App 级 delegate。
///
/// 当前主要负责：
/// - 响应 `UIApplication` 生命周期事件（将来可用于后台任务管理等）
///
/// 音频的中断处理已由 `AudioSessionManager` 在 Service 层直接监听
/// `AVAudioSession` 通知，不需要通过 AppDelegate 中转。
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }
}
