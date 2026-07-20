//
//  UnhurryApp.swift
//  Unhurry
//

import SwiftUI

@main
struct UnhurryApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let audioService = AudioService()
    private let soundLibrary = SoundLibrary()
    private let sleepTimer: SleepTimer
    private let ttsService = TTSService()

    private let playerVM: SoundPlayerViewModel
    private let timerVM: TimerViewModel
    private let storyVM: StoryPlayerViewModel

    init() {
        sleepTimer = SleepTimer(audioService: audioService)
        playerVM = SoundPlayerViewModel(audioService: audioService, soundLibrary: soundLibrary)
        timerVM = TimerViewModel(sleepTimer: sleepTimer)
        storyVM = StoryPlayerViewModel(ttsService: ttsService, sleepTimer: sleepTimer)

        // 通知点击 → 加载对应预设
        appDelegate.onNotificationPreset = { [weak playerVM] presetId in
            guard let playerVM,
                  let uuid = UUID(uuidString: presetId),
                  let preset = playerVM.presets.first(where: { $0.id == uuid })
            else { return }
            playerVM.loadPreset(preset)
        }

        // Siri / Shortcuts Intent 桥接
        IntentBridge.onStartSleep = { [weak playerVM] in
            playerVM?.loadLastOrDefaultPreset()
        }
        IntentBridge.onStopSounds = { [weak playerVM, weak storyVM] in
            playerVM?.stopAll()
            storyVM?.stop()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(playerVM: playerVM, timerVM: timerVM, storyVM: storyVM)
                .onAppear {
                    soundLibrary.preloadBuiltInSounds(into: audioService)
                }
                .task {
                    await HealthService.requestAuthorization()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    // MARK: - Deep Link

    /// 处理 Widget 点击传入的 URL（unhurry://play?id=UUID）
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "unhurry",
              url.host == "play",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
              let uuid = UUID(uuidString: idString),
              let preset = playerVM.presets.first(where: { $0.id == uuid })
        else { return }

        playerVM.loadPreset(preset)
    }
}
