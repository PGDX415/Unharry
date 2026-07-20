//
//  StoryPlayerView.swift
//  Unhurry
//

import SwiftUI

/// 故事/冥想播放器——TTS 朗读 / 预录音频 + 文字稿同步滚动。
struct StoryPlayerView: View {

    let viewModel: StoryPlayerViewModel
    let story: StoryItem

    @Environment(\.dismiss) private var dismiss
    @State private var countdown: Int = 3

    private let accentColor = Color(red: 0.941, green: 0.902, blue: 0.824)
    private let bgColor = Color(red: 0.216, green: 0.184, blue: 0.322)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            // 播放主界面
            VStack(spacing: 0) {
                headerBar

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
        .background(bgColor.opacity(0.95))
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
        attributed.foregroundColor = UIColor(accentColor).withAlphaComponent(0.5)

        if let range = viewModel.highlightedRange,
           let swiftRange = Range(range, in: text),
           let lower = AttributedString.Index(swiftRange.lowerBound, within: attributed),
           let upper = AttributedString.Index(swiftRange.upperBound, within: attributed) {
            attributed[lower..<upper].foregroundColor = UIColor(accentColor)
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
                .fill(Color(red: 0.216, green: 0.184, blue: 0.322))
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
