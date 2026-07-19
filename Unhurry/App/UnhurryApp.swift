//
//  UnhurryApp.swift
//  Unhurry
//

import SwiftUI

@main
struct UnhurryApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// App 级共享服务实例
    /// 使用 `let` 而非 `@State`：这些对象在 App 生命周期内身份不变，
    /// 无需 SwiftUI 响应式追踪。
    private let audioService = AudioService()
    private let soundLibrary = SoundLibrary()
    private let sleepTimer: SleepTimer

    init() {
        sleepTimer = SleepTimer(audioService: audioService)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                audioService: audioService,
                soundLibrary: soundLibrary,
                sleepTimer: sleepTimer
            )
            .onAppear {
                soundLibrary.preloadBuiltInSounds(into: audioService)
            }
        }
    }
}
