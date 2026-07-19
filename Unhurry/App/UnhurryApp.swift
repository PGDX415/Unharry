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

    private let playerVM: SoundPlayerViewModel
    private let timerVM: TimerViewModel

    init() {
        sleepTimer = SleepTimer(audioService: audioService)
        playerVM = SoundPlayerViewModel(audioService: audioService, soundLibrary: soundLibrary)
        timerVM = TimerViewModel(sleepTimer: sleepTimer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(playerVM: playerVM, timerVM: timerVM)
                .onAppear {
                    soundLibrary.preloadBuiltInSounds(into: audioService)
                }
        }
    }
}
