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
    }

    var body: some Scene {
        WindowGroup {
            ContentView(playerVM: playerVM, timerVM: timerVM, storyVM: storyVM)
                .onAppear {
                    soundLibrary.preloadBuiltInSounds(into: audioService)
                }
        }
    }
}
