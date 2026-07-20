//
//  StoryPlayerView.swift
//  Unhurry
//

import SwiftUI

/// 故事/冥想播放器——TTS 朗读 / 预录音频 + 文字稿同步滚动。
struct StoryPlayerView: View {

    let viewModel: StoryPlayerViewModel
    let story: StoryItem
    let soundPlayerVM: SoundPlayerViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var countdown: Int = 3
    @State private var showBackgroundSounds = false
    @AppStorage("useBlackBackground") private var useBlackBg = false

    private var accentColor: Color { Theme.accentColor }
    private var bgColor: Color { Theme.bgColor }

    var body: some View {
        ZStack {
            (useBlackBg ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor).ignoresSafeArea()

            // 播放主界面
            VStack(spacing: 0) {
                headerBar

                backgroundSoundStrip

                if let story = viewModel.currentStory {
                    textContent(story.content)
                }

                controlBar
            }
            .foregroundStyle(accentColor)

            // 准备缓冲遮罩
            if viewModel.isPreparing {
                preparationOverlay
            }
        }
        .foregroundStyle(accentColor)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.play(story)
            startCountdown()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    // MARK: - Preparation Overlay

    private var preparationOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: story.category.iconName)
                .font(.system(size: 48))
                .foregroundStyle(accentColor.opacity(0.6))

            Text(story.title)
                .font(.title2)
                .fontWeight(.medium)

            Text("闭上眼睛，放松身体……")
                .font(.subheadline)
                .foregroundStyle(accentColor.opacity(0.5))

            Text("\(countdown)")
                .font(.system(size: 64, design: .rounded))
                .fontWeight(.thin)
                .foregroundStyle(accentColor.opacity(0.6))
                .contentTransition(.numericText())

            Text("轻点屏幕 立即开始")
                .font(.caption)
                .foregroundStyle(accentColor.opacity(0.3))
                .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background((useBlackBg ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor).opacity(0.95))
        .onTapGesture {
            viewModel.skipPreparation()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: {
                viewModel.stop()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.body)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(story.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(story.category.displayName)
                    .font(.caption2)
                    .foregroundStyle(accentColor.opacity(0.45))
            }

            Spacer()

            // 对称占位
            Image(systemName: "chevron.left")
                .font(.body)
                .opacity(0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Background Sound Strip

    /// 常用背景音（供睡前故事页面快速切换）
    private static let quickSoundIDs: [String] = [
        "ai_rain_light",
        "ai_ocean_calm",
        "ai_fire_camp",
        "builtin_white_noise",
        "ai_fan_hum",
        "ai_summer_bugs",
    ]

    private var backgroundSoundStrip: some View {
        let hasActive = soundPlayerVM.isAnythingPlaying || soundPlayerVM.isSoundPreparing
        let activeHighlight = soundPlayerVM.allActiveOrPendingIds

        return VStack(spacing: 0) {
            // Toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showBackgroundSounds.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: hasActive ? "speaker.wave.2.fill" : "speaker.wave.1")
                        .font(.caption)
                        .foregroundStyle(hasActive ? accentColor : accentColor.opacity(0.4))

                    Text("背景音")
                        .font(.caption)
                        .foregroundStyle(accentColor.opacity(0.55))

                    if hasActive {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 5, height: 5)
                    }

                    Spacer()

                    Image(systemName: showBackgroundSounds ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(accentColor.opacity(0.35))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(accentColor.opacity(0.04))
            }
            .buttonStyle(.plain)

            // Sound chips
            if showBackgroundSounds {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Self.quickSoundIDs, id: \.self) { trackId in
                            bgChip(trackId: trackId, isActive: activeHighlight.contains(trackId))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func bgChip(trackId: String, isActive: Bool) -> some View {
        let name = soundPlayerVM.name(for: trackId)

        return Button(action: {
            guard let track = soundPlayerVM.tracks.first(where: { $0.id == trackId }) else { return }
            soundPlayerVM.toggleTrack(track)
        }) {
            HStack(spacing: 4) {
                Image(systemName: isActive ? "speaker.wave.2.fill" : "speaker.wave.1")
                    .font(.system(size: 8))
                Text(name)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isActive ? accentColor.opacity(0.25) : accentColor.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Text Content

    private func textContent(_ fullText: String) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 使用 AttributedString 实现高亮
                    Text(highlightedAttributedString(from: fullText))
                        .font(.system(size: 18, design: .serif))
                        .lineSpacing(10)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .onChange(of: viewModel.highlightedRange) { _, _ in
                // 自动滚动到当前朗读位置
                if let range = viewModel.highlightedRange {
                    let targetPos = min(range.location + range.length, fullText.count)
                    let index = fullText.index(fullText.startIndex, offsetBy: max(0, targetPos - 1))
                    let lineID = String(fullText[..<index].filter { $0 == "\n" }.count)
                    withAnimation {
                        proxy.scrollTo(lineID, anchor: .center)
                    }
                }
            }
        }
    }

    /// 构造高亮的 AttributedString。
    /// 当前朗读的句子用暖白色全亮，其余为 50% 透明度。
    private func highlightedAttributedString(from text: String) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = Theme.accent.uiColor.withAlphaComponent(0.5)

        if let range = viewModel.highlightedRange,
           let swiftRange = Range(range, in: text),
           let lower = AttributedString.Index(swiftRange.lowerBound, within: attributed),
           let upper = AttributedString.Index(swiftRange.upperBound, within: attributed) {
            attributed[lower..<upper].foregroundColor = Theme.accent.uiColor
        }

        return attributed
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 40) {
            // 后退 10 秒（约 35 字）
            Button(action: { seekBackward() }) {
                Image(systemName: "gobackward.10")
                    .font(.title2)
            }

            // 播放/暂停
            Button(action: { viewModel.togglePause() }) {
                Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 52))
            }

            // 停止
            Button(action: {
                viewModel.stop()
                dismiss()
            }) {
                Image(systemName: "stop.circle.fill")
                    .font(.title2)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(useBlackBg ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor)
                .shadow(color: .black.opacity(0.3), radius: 8, y: -2)
        )
    }

    // MARK: - Countdown

    private func startCountdown() {
        countdown = 3
        Task {
            for i in (1...3).reversed() {
                try? await Task.sleep(for: .seconds(1))
                guard viewModel.isPreparing else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    countdown = i - 1
                }
            }
        }
    }

    // MARK: - Actions

    private func seekBackward() {
        guard let range = viewModel.highlightedRange else { return }
        // 使用高亮区段末端作为「当前朗读位置」
        let currentPos = range.location + range.length
        let newLocation = max(0, currentPos - 35)
        viewModel.seek(to: newLocation)
    }
}
