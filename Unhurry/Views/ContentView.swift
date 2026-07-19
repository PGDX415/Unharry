//
//  ContentView.swift
//  Unhurry
//

import SwiftUI

struct ContentView: View {

    let playerVM: SoundPlayerViewModel
    let timerVM: TimerViewModel
    let storyVM: StoryPlayerViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                brandHeader
                storyEntry
                breathEntry
                TimerControlView(viewModel: timerVM)
                SoundLibraryView(viewModel: playerVM)
                ActiveMixerPanel(viewModel: playerVM)
            }
            .background(Color(red: 0.216, green: 0.184, blue: 0.322))
            .foregroundStyle(Color(red: 0.941, green: 0.902, blue: 0.824))
        }
    }

    // MARK: - Breath Entry

    private var breathEntry: some View {
        NavigationLink(destination: BreathView()) {
            HStack {
                Label("呼吸练习", systemImage: "wind")
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(red: 0.941, green: 0.902, blue: 0.824).opacity(0.06))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Story Entry

    private var storyEntry: some View {
        NavigationLink(destination: StoryLibraryView(viewModel: storyVM)) {
            HStack {
                Label("睡前陪伴", systemImage: "book.fill")
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(red: 0.941, green: 0.902, blue: 0.824).opacity(0.06))
        }
        .buttonStyle(.plain)
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
        timerVM: TimerViewModel(sleepTimer: sleepTimer),
        storyVM: StoryPlayerViewModel(sleepTimer: sleepTimer)
    )
}
