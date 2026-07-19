//
//  ContentView.swift
//  Unhurry
//
//  MVP 测试界面：验证 AudioService + SleepTimer 基本功能。
//  后续将替换为正式 UI。
//

import SwiftUI

struct ContentView: View {

    let audioService: AudioServiceProtocol
    let soundLibrary: SoundLibrary
    let sleepTimer: SleepTimer

    @State private var activeSoundId: String?
    @State private var timerRemaining: TimeInterval = 0
    @State private var timerRunning = false

    var body: some View {
        VStack(spacing: 16) {
            // 品牌区
            headerView

            Divider()
                .background(Color(red: 0.941, green: 0.902, blue: 0.824).opacity(0.3))

            // 音频测试区
            audioTestSection

            Divider()
                .background(Color(red: 0.941, green: 0.902, blue: 0.824).opacity(0.3))

            // 计时器测试区
            timerTestSection
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.216, green: 0.184, blue: 0.322))
        .foregroundStyle(Color(red: 0.941, green: 0.902, blue: 0.824))
        .onAppear {
            sleepTimer.onTick = { remaining in
                timerRemaining = remaining
                timerRunning = true
            }
            sleepTimer.onFinish = {
                timerRunning = false
                activeSoundId = nil
            }
            sleepTimer.onCancel = {
                timerRunning = false
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 44))
            Text("闲眠")
                .font(.title)
                .fontWeight(.medium)

            // 白居易《闲眠》
            Text("暖床斜卧日曛腰，一觉闲眠百病销")
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundStyle(Color(red: 0.941, green: 0.902, blue: 0.824).opacity(0.7))

            Text("AudioService 种子音频测试")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Audio Test

    private var audioTestSection: some View {
        VStack(spacing: 10) {
            Text("音频播放")
                .font(.headline)

            if let active = activeSoundId {
                Text("正在播放: \(soundName(for: active))")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else {
                Text("未播放")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                ForEach(soundLibrary.tracks) { track in
                    Button(action: { toggleSound(track) }) {
                        VStack(spacing: 4) {
                            Image(systemName: activeSoundId == track.id ? "stop.circle.fill" : "play.circle")
                                .font(.title2)
                            Text(track.name)
                                .font(.caption2)
                        }
                    }
                }
            }

            // 多轨混音测试
            Button(action: playMultipleTracks) {
                Label("同时播放三种噪音（混音测试）", systemImage: "speaker.wave.2.fill")
                    .font(.caption)
            }
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timer Test

    private var timerTestSection: some View {
        VStack(spacing: 10) {
            Text("睡眠计时器")
                .font(.headline)

            if timerRunning {
                Text("剩余 \(formatTime(timerRemaining))")
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(.yellow)

                Button(role: .destructive, action: { sleepTimer.cancel() }) {
                    Label("取消计时", systemImage: "xmark.circle.fill")
                }
            } else {
                Text("设定计时后自动渐弱停止")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ForEach([10, 15, 30], id: \.self) { seconds in
                        Button(action: { startTimer(seconds: TimeInterval(seconds)) }) {
                            Text("\(seconds)秒")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(red: 0.941, green: 0.902, blue: 0.824).opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func toggleSound(_ track: SoundTrack) {
        if activeSoundId == track.id {
            audioService.stop(soundId: track.id)
            activeSoundId = nil
        } else {
            // 先停掉之前的
            if let prev = activeSoundId {
                audioService.stop(soundId: prev)
            }
            do {
                try audioService.play(
                    soundId: track.id,
                    volume: track.defaultVolume,
                    loop: track.isLoopable
                )
                activeSoundId = track.id
            } catch {
                print("Play failed: \(error)")
            }
        }
    }

    private func playMultipleTracks() {
        // 停掉所有
        audioService.stopAll()
        activeSoundId = nil

        // 同时播放三个（混音测试）
        let configs: [(String, Float)] = [
            (SoundLibrary.BuiltIn.whiteNoise.rawValue, 0.3),
            (SoundLibrary.BuiltIn.pinkNoise.rawValue, 0.3),
            (SoundLibrary.BuiltIn.brownNoise.rawValue, 0.25),
        ]
        for (id, vol) in configs {
            do {
                try audioService.play(soundId: id, volume: vol, loop: true)
            } catch {
                print("Multi-track play failed for \(id): \(error)")
            }
        }
    }

    private func startTimer(seconds: TimeInterval) {
        // 先播放一个声音以测试渐弱
        if activeSoundId == nil {
            let id = SoundLibrary.BuiltIn.whiteNoise.rawValue
            do {
                try audioService.play(soundId: id, volume: 0.4, loop: true)
                activeSoundId = id
            } catch {
                print("Pre-timer play failed: \(error)")
            }
        }
        let fadeDuration = max(3.0, seconds * 0.2) // 最后 20% 时间渐弱，最少 3 秒
        sleepTimer.start(duration: seconds, fadeOutDuration: fadeDuration)
    }

    // MARK: - Helpers

    private func soundName(for id: String) -> String {
        soundLibrary.tracks.first { $0.id == id }?.name ?? id
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    let audioService = AudioService()
    let library = SoundLibrary()
    library.preloadBuiltInSounds(into: audioService)
    let timer = SleepTimer(audioService: audioService)
    return ContentView(
        audioService: audioService,
        soundLibrary: library,
        sleepTimer: timer
    )
}
