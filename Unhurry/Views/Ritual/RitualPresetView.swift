//
//  RitualPresetView.swift
//  Unhurry
//

import SwiftUI

/// 入睡仪式选择页——展示内置仪式模板卡片。
struct RitualPresetView: View {

    let playerVM: SoundPlayerViewModel
    let timerVM: TimerViewModel

    @AppStorage("useBlackBackground") private var useBlackBg = false
    private var accentColor: Color { Theme.accentColor }

    private let rituals = SleepRitual.presets

    var body: some View {
        ZStack {
            (useBlackBg ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("选择一个仪式，然后闭上眼睛，把一切交给它")
                        .font(.caption)
                        .foregroundStyle(accentColor.opacity(0.45))
                        .padding(.bottom, 4)

                    ForEach(rituals) { ritual in
                        ritualCard(ritual)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .foregroundStyle(accentColor)
        .navigationTitle("入睡仪式")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Ritual Card

    private func ritualCard(_ ritual: SleepRitual) -> some View {
        NavigationLink(destination: {
            SleepRitualView(
                ritual: ritual,
                viewModel: SleepRitualViewModel(playerVM: playerVM, timerVM: timerVM)
            )
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: ritual.icon)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(accentColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(ritual.name)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(ritual.description)
                            .font(.caption)
                            .foregroundStyle(accentColor.opacity(0.55))
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(accentColor.opacity(0.5))
                }

                // 步骤预览
                HStack(spacing: 6) {
                    ForEach(Array(ritual.steps.enumerated()), id: \.offset) { idx, step in
                        HStack(spacing: 4) {
                            Image(systemName: step.iconName)
                                .font(.system(size: 8))
                            Text(step.displayName)
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(accentColor.opacity(0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.08))
                        )

                        if idx < ritual.steps.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 6))
                                .foregroundStyle(accentColor.opacity(0.2))
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(accentColor.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}
