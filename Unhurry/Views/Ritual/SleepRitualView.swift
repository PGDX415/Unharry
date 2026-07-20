//
//  SleepRitualView.swift
//  Unhurry
//

import SwiftUI

/// 入睡仪式全屏视图——编排呼吸 → 音效 → 计时器。
struct SleepRitualView: View {

    let ritual: SleepRitual
    @State var viewModel: SleepRitualViewModel

    @Environment(\.dismiss) private var dismiss
    @AppStorage("useBlackBackground") private var useBlackBg = false

    private var accentColor: Color { Theme.accentColor }

    var body: some View {
        ZStack {
            (useBlackBg ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                Spacer()

                mainContent

                Spacer()

                bottomControls
            }
        }
        .foregroundStyle(accentColor)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if viewModel.phase == .idle {
                viewModel.start(ritual: ritual)
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: {
                viewModel.cancel()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.body)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(ritual.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("入睡仪式")
                    .font(.caption2)
                    .foregroundStyle(accentColor.opacity(0.45))
            }

            Spacer()

            Image(systemName: "xmark").opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()
        case .countdown(let count):
            countdownView(count)
        case .running(let stepIndex):
            runningView(stepIndex: stepIndex)
        case .paused:
            pausedView
        case .finished:
            finishedView
        case .cancelled:
            EmptyView()
        }
    }

    // MARK: - Countdown

    private func countdownView(_ count: Int) -> some View {
        VStack(spacing: 24) {
            Image(systemName: ritual.icon)
                .font(.system(size: 48))
                .foregroundStyle(accentColor.opacity(0.6))

            Text(ritual.name)
                .font(.title2)
                .fontWeight(.medium)

            Text("放松身体，闭上眼睛……")
                .font(.subheadline)
                .foregroundStyle(accentColor.opacity(0.5))

            Text("\(count)")
                .font(.system(size: 72, design: .rounded))
                .fontWeight(.thin)
                .foregroundStyle(accentColor.opacity(0.6))
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: count)

            // 步骤预览
            HStack(spacing: 4) {
                ForEach(Array(ritual.steps.enumerated()), id: \.offset) { idx, step in
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 8, height: 8)
                    if idx < ritual.steps.count - 1 {
                        Rectangle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 16, height: 2)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Running

    private func runningView(stepIndex: Int) -> some View {
        VStack(spacing: 24) {
            // 步骤进度条
            stepProgressBar

            // 当前步骤内容
            currentStepContent(stepIndex: stepIndex)

            // 步骤名 + 计时
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.currentStepIcon())
                        .font(.caption)
                    Text(viewModel.currentStepName())
                        .font(.subheadline)
                }
                .foregroundStyle(accentColor.opacity(0.6))

                if case .timer = ritual.steps[stepIndex] {
                    Text(viewModel.formatRemaining())
                        .font(.system(size: 36, design: .rounded).monospacedDigit())
                        .fontWeight(.thin)
                } else if case .breath = ritual.steps[stepIndex] {
                    Text(viewModel.formatRemaining())
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(accentColor.opacity(0.45))
                }
            }
        }
    }

    // MARK: - Step Progress

    private var stepProgressBar: some View {
        HStack(spacing: 4) {
            ForEach(Array(ritual.steps.enumerated()), id: \.offset) { idx, step in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(accentColor.opacity(0.1))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(accentColor.opacity(viewModel.stepProgress(at: idx) > 0 ? 0.6 : 0.1))
                            .frame(width: geo.size.width * viewModel.stepProgress(at: idx), height: 6)
                            .animation(.easeInOut(duration: 0.5), value: viewModel.stepProgress(at: idx))
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step Content

    @ViewBuilder
    private func currentStepContent(stepIndex: Int) -> some View {
        let step = ritual.steps[stepIndex]

        switch step {
        case .breath:
            breathCircle
        case .sounds:
            soundsView
        case .timer:
            timerView
        }
    }

    // MARK: - Breath Circle

    private var breathCircle: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.15), lineWidth: 2)
                .frame(width: 180, height: 180)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.22), accentColor.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 150, height: 150)
                .scaleEffect(viewModel.breathScale)
                .animation(.easeInOut(duration: 0.12), value: viewModel.breathScale)

            VStack(spacing: 8) {
                Text(viewModel.breathPhase.rawValue)
                    .font(.title2)
                    .fontWeight(.light)
                    .contentTransition(.identity)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.breathPhase)

                Text("跟随圆圈的节奏")
                    .font(.caption)
                    .foregroundStyle(accentColor.opacity(0.4))
            }
        }
    }

    // MARK: - Sounds

    private var soundsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 32))
                .foregroundStyle(accentColor.opacity(0.5))
                .symbolEffect(.pulse)

            Text("正在为你营造环境……")
                .font(.subheadline)
                .foregroundStyle(accentColor.opacity(0.5))
        }
    }

    // MARK: - Timer

    private var timerView: some View {
        VStack(spacing: 12) {
            Circle()
                .trim(from: 0, to: viewModel.stepDuration > 0
                    ? (1 - viewModel.stepElapsed / viewModel.stepDuration)
                    : 1)
                .stroke(
                    accentColor.opacity(0.3),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 100, height: 100)
                .animation(.linear(duration: 0.5), value: viewModel.stepElapsed)

            Image(systemName: "moon.zzz.fill")
                .font(.title)
                .foregroundStyle(accentColor.opacity(0.5))
        }
    }

    // MARK: - Paused

    private var pausedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(accentColor.opacity(0.5))
            Text("已暂停")
                .font(.title3)
                .foregroundStyle(accentColor.opacity(0.5))
        }
    }

    // MARK: - Finished

    private var finishedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(accentColor.opacity(0.7))

            Text("仪式完成")
                .font(.title2)
                .fontWeight(.medium)

            Text("音效将继续伴你入眠")
                .font(.subheadline)
                .foregroundStyle(accentColor.opacity(0.45))

            Button(action: { dismiss() }) {
                Text("返回")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomControls: some View {
        if case .running = viewModel.phase {
            HStack(spacing: 40) {
                Button(action: { viewModel.skipCurrentStep() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                        Text("跳过")
                            .font(.caption2)
                    }
                    .foregroundStyle(accentColor.opacity(0.5))
                }

                Button(action: { viewModel.cancel(); dismiss() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundStyle(.red.opacity(0.6))
                        Text("结束")
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.6))
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
}
