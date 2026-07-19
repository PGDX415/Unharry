//
//  TimerControlView.swift
//  Unhurry
//

import SwiftUI

/// 睡眠计时器控件。
///
/// 展示预设时长按钮 + 倒计时 + 取消操作。
struct TimerControlView: View {

    let viewModel: TimerViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "timer")
                Text("睡眠计时器")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .foregroundStyle(.secondary)

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
            ForEach(viewModel.presets, id: \.seconds) { preset in
                Button(action: { viewModel.start(duration: preset.seconds) }) {
                    Text(preset.label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.941, green: 0.902, blue: 0.824).opacity(0.12))
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
                .foregroundStyle(Color(red: 0.941, green: 0.902, blue: 0.824))

            Spacer()

            Button(role: .destructive, action: { viewModel.cancel() }) {
                Label("取消", systemImage: "xmark.circle.fill")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
    }
}
