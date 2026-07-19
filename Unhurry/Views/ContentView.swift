//
//  ContentView.swift
//  Unhurry
//

import SwiftUI

struct ContentView: View {

    let playerVM: SoundPlayerViewModel
    let timerVM: TimerViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 品牌头
            brandHeader

            // 计时器
            TimerControlView(viewModel: timerVM)

            // 音效库（可滚动）
            SoundLibraryView(viewModel: playerVM)

            // 底部混音面板（播放时浮现）
            ActiveMixerPanel(viewModel: playerVM)
        }
        .background(Color(red: 0.216, green: 0.184, blue: 0.322))
        .foregroundStyle(Color(red: 0.941, green: 0.902, blue: 0.824))
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        VStack(spacing: 4) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 36))
                .padding(.top, 8)

            Text("闲眠")
                .font(.title2)
                .fontWeight(.medium)

            // 白居易《闲眠》
            Text("暖床斜卧日曛腰，一觉闲眠百病销")
                .font(.system(size: 11, design: .serif))
                .italic()
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.216, green: 0.184, blue: 0.322))
    }
}

#Preview {
    let audioService = AudioService()
    let library = SoundLibrary()
    library.preloadBuiltInSounds(into: audioService)
    let sleepTimer = SleepTimer(audioService: audioService)
    return ContentView(
        playerVM: SoundPlayerViewModel(audioService: audioService, soundLibrary: library),
        timerVM: TimerViewModel(sleepTimer: sleepTimer)
    )
}
