//
//  StoryPlayerView.swift
//  Unhurry
//

import SwiftUI

/// 故事/冥想播放器——TTS 朗读 + 文字稿同步滚动。
struct StoryPlayerView: View {

    let viewModel: StoryPlayerViewModel
    let story: StoryItem

    @Environment(\.dismiss) private var dismiss

    private let accentColor = Color(red: 0.941, green: 0.902, blue: 0.824)

    var body: some View {
        VStack(spacing: 0) {
            // 顶部信息栏
            headerBar

            // 文字稿（可滚动）
            if let story = viewModel.currentStory {
                textContent(story.content)
            }

            // 底部播放控制
            controlBar
        }
        .background(Color(red: 0.216, green: 0.184, blue: 0.322))
        .foregroundStyle(accentColor)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.play(story)
        }
        .onDisappear {
            viewModel.stop()
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
                    .foregroundStyle(.secondary)
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
            .onChange(of: viewModel.highlightedRange?.location) { _, _ in
                // 自动滚动到当前朗读位置
                if let range = viewModel.highlightedRange,
                   range.location < fullText.count {
                    let index = fullText.index(fullText.startIndex, offsetBy: range.location)
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

    // MARK: - Actions

    private func seekBackward() {
        guard let range = viewModel.highlightedRange else { return }
        let newLocation = max(0, range.location - 35)
        viewModel.seek(to: newLocation)
    }
}
