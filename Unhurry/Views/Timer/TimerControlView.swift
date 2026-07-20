//
//  TimerControlView.swift
//  Unhurry
//

import SwiftUI

/// 睡眠/专注计时器控件。
///
/// 展示预设时长按钮 + 倒计时 + 取消操作。
/// 专注模式使用番茄钟预设（25/45/60 分钟）。
struct TimerControlView: View {

    let viewModel: TimerViewModel
    let isFocusMode: Bool

    private var currentPresets: [(label: String, seconds: TimeInterval)] {
        isFocusMode
            ? [("25 分钟", 25 * 60), ("45 分钟", 45 * 60), ("60 分钟", 60 * 60)]
            : viewModel.presets
    }

    private var timerLabel: String {
        isFocusMode ? "专注计时器" : "睡眠计时器"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: isFocusMode ? "clock.badge" : "timer")
                Text(timerLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .foregroundStyle(Theme.accentColor.opacity(0.5))

            if viewModel.isRunning {
                runningState
            } else {
                presetButtons
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Preset Buttons

    private var presetButtons: some View {
        HStack(spacing: 8) {
            ForEach(currentPresets, id: \.seconds) { preset in
                Button(action: { viewModel.start(duration: preset.seconds) }) {
                    Text(preset.label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.accentColor.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Running State

    private var runningState: some View {
        HStack {
            Label("剩余 \(viewModel.formattedTime)", systemImage: "timer.circle.fill")
                .font(.title3.monospacedDigit())
                .foregroundStyle(Theme.accentColor)

            Spacer()

            Button(role: .destructive, action: { viewModel.cancel() }) {
                Label("取消", systemImage: "xmark.circle.fill")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
    }
}
