//
//  BreathView.swift
//  Unhurry
//

import SwiftUI

/// 呼吸引导练习——动画圆圈 + 震动同步。
struct BreathView: View {
    @State var viewModel = BreathViewModel()
    @Environment(\.dismiss) private var dismiss
    @AppStorage("useBlackBackground") private var useBlackBg = false

    private var accentColor: Color { Theme.accentColor }

    var body: some View {
        ZStack {
            (useBlackBg ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor).ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部
                headerBar

                Spacer()

                // 呼吸圆环
                breathCircle

                // 引导文字
                if viewModel.state != .idle {
                    phaseLabel
                }

                Spacer()

                // 底部控制
                bottomControls
            }
        }
        .foregroundStyle(accentColor)
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            viewModel.stop()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            if viewModel.state == .idle || viewModel.state == .finished {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.body)
                }
            } else {
                Button(action: {
                    viewModel.stop()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.body)
                }
            }
            Spacer()
            Text("呼吸练习")
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Image(systemName: "xmark").opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Breath Circle

    private var breathCircle: some View {
        ZStack {
            // 外光圈
            Circle()
                .stroke(accentColor.opacity(0.15), lineWidth: 2)
                .frame(width: 240, height: 240)

            // 呼吸圆
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.25), accentColor.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(viewModel.scale)
                .animation(.easeInOut(duration: 0.1), value: viewModel.scale)

            // 中心图标
            if viewModel.state == .idle {
                Image(systemName: "camera.macro")
                    .font(.system(size: 48))
                    .foregroundStyle(accentColor.opacity(0.5))
            } else if viewModel.state == .finished {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                    Text("完成")
                        .font(.caption)
                }
                .foregroundStyle(accentColor.opacity(0.6))
            }
        }
    }

    // MARK: - Phase Label

    private var phaseLabel: some View {
        VStack(spacing: 12) {
            Text(viewModel.currentPhase == .inhale ? "吸气" : "呼气")
                .font(.title)
                .fontWeight(.light)
                .contentTransition(.identity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentPhase)

            Text("第 \(viewModel.breathCount + 1) 次呼吸")
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))
        }
        .padding(.top, 40)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 20) {
            switch viewModel.state {
            case .idle:
                idleControls
            case .running, .paused:
                runningControls
            case .finished:
                finishedControls
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Idle State

    private var idleControls: some View {
        VStack(spacing: 16) {
            Text("选择时长")
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))

            HStack(spacing: 12) {
                ForEach(viewModel.presets, id: \.1) { name, seconds in
                    Button(action: {
                        viewModel.selectPreset(seconds: seconds)
                    }) {
                        Text(name)
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.totalDuration == seconds
                                    ? accentColor.opacity(0.2)
                                    : accentColor.opacity(0.06)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: { viewModel.start() }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("开始呼吸")
                }
                .font(.title3)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    // MARK: - Running State

    private var runningControls: some View {
        VStack(spacing: 16) {
            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(accentColor.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(accentColor.opacity(0.5))
                        .frame(width: geo.size.width * (viewModel.elapsed / viewModel.totalDuration), height: 6)
                        .animation(.linear(duration: 0.5), value: viewModel.elapsed)
                }
            }
            .frame(height: 6)

            // 剩余时间
            Text(formatRemaining())
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))

            // 暂停/停止
            HStack(spacing: 40) {
                Button(action: { viewModel.togglePause() }) {
                    Image(systemName: viewModel.state == .paused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 48))
                }
                .buttonStyle(.plain)

                Button(action: {
                    viewModel.stop()
                    dismiss()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Finished State

    private var finishedControls: some View {
        VStack(spacing: 16) {
            Text("呼吸练习完成")
                .font(.subheadline)
                .foregroundStyle(Theme.accentColor.opacity(0.5))

            HStack(spacing: 20) {
                Button(action: { viewModel.start() }) {
                    Label("再来一次", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)

                Button(action: { dismiss() }) {
                    Label("返回", systemImage: "house.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func formatRemaining() -> String {
        let remaining = max(0, viewModel.totalDuration - viewModel.elapsed)
        let m = Int(remaining) / 60
        let s = Int(remaining) % 60
        return "剩余 \(m):\(String(format: "%02d", s))"
    }
}

#Preview {
    NavigationStack {
        BreathView()
    }
}
