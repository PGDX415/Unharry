//
//  ContentView.swift
//  Unhurry
//

import SwiftUI

struct ContentView: View {

    let playerVM: SoundPlayerViewModel
    let timerVM: TimerViewModel
    let storyVM: StoryPlayerViewModel

    @State private var showSettings = false
    @AppStorage("useBlackBackground") private var useBlackBackground = false
    @AppStorage("accentTheme") private var accentTheme = "gold"
    @AppStorage("isFocusMode") private var isFocusMode = false

    /// 主题变化时递增，强制重建整个视图树
    @State private var themeVersion = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                brandHeader
                modePicker

                if !isFocusMode {
                    ritualEntry
                    storyEntry
                    breathEntry
                }

                TimerControlView(viewModel: timerVM, isFocusMode: isFocusMode)
                AudioVisualizerView(
                    magnitudes: playerVM.visualizer.magnitudes,
                    hasSignal: playerVM.visualizer.hasSignal
                )
                SoundLibraryView(viewModel: playerVM)
                ActiveMixerPanel(viewModel: playerVM)
            }
            .animation(.smooth(duration: 0.3), value: isFocusMode)
            .background(useBlackBackground ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor)
            .foregroundStyle(Theme.accentColor)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.subheadline)
                    }
                    .accessibilityLabel("设置")
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView(
                        nameResolver: { playerVM.name(for: $0) },
                        presets: playerVM.presets,
                        onImportTrack: { playerVM.importCustomTrack(from: $0) }
                    )
                }
            }
            .id(themeVersion)
            .onChange(of: accentTheme) { _, _ in themeVersion += 1 }
            .onChange(of: useBlackBackground) { _, _ in themeVersion += 1 }
        }
    }

    // MARK: - Breath Entry

    private var breathEntry: some View {
        NavigationLink(destination: BreathView()) {
            HStack {
                Label("呼吸练习", systemImage: "wind")
                    .font(.caption)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Theme.accentColor.opacity(0.45))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 7)
            .background(Theme.accentColor.opacity(0.06))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Story Entry

    private var storyEntry: some View {
        NavigationLink(destination: StoryLibraryView(viewModel: storyVM, soundPlayerVM: playerVM)) {
            HStack {
                Label("睡前陪伴", systemImage: "book.fill")
                    .font(.caption)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Theme.accentColor.opacity(0.45))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 7)
            .background(Theme.accentColor.opacity(0.06))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: isFocusMode ? "brain.head.profile" : "moon.stars.fill")
                    .font(.title3)
                Text("闲眠")
                    .font(.title3)
                    .fontWeight(.medium)
            }

            Text(isFocusMode ? "静以修身，俭以养德" : "暖床斜卧日曛腰，一觉闲眠百病销")
                .font(.system(size: 10, design: .serif))
                .italic()
                .foregroundStyle(Theme.accentColor.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background(useBlackBackground ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor)
    }

    // MARK: - Ritual Entry

    private var ritualEntry: some View {
        NavigationLink(destination: RitualPresetView(playerVM: playerVM, timerVM: timerVM)) {
            HStack {
                Label("入睡仪式", systemImage: "sparkles")
                    .font(.caption)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Theme.accentColor.opacity(0.45))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 7)
            .background(Theme.accentColor.opacity(0.06))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("模式", selection: $isFocusMode) {
            Text("助眠").tag(false)
            Text("专注").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .sensoryFeedback(.selection, trigger: isFocusMode)
    }
}

#Preview {
    let audioService = AudioService()
    let library = SoundLibrary()
    library.preloadBuiltInSounds(into: audioService)
    let sleepTimer = SleepTimer(audioService: audioService)
    return ContentView(
        playerVM: SoundPlayerViewModel(audioService: audioService, soundLibrary: library, nowPlayingController: NowPlayingController()),
        timerVM: TimerViewModel(sleepTimer: sleepTimer),
        storyVM: StoryPlayerViewModel(ttsService: TTSService(), sleepTimer: sleepTimer, stories: StoryItem.builtIn)
    )
}
