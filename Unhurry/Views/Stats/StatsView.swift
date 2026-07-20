//
//  StatsView.swift
//  Unhurry
//

import SwiftUI

/// 使用统计页——本周入睡次数、累计收听时长、最爱音效排行。
struct StatsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var tracker = UsageTracker.shared

    /// 外部注入音效名称解析器（ViewModel 提供）
    let nameResolver: (String) -> String
    @AppStorage("useBlackBackground") private var useBlackBg = false

    var body: some View {
        ZStack {
            (useBlackBg ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    summaryCards
                    topTracksSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .foregroundStyle(Theme.accentColor)
        .navigationTitle("使用统计")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { dismiss() }
                    .foregroundStyle(Theme.accentColor)
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            statCard(
                title: "本周入睡",
                value: "\(tracker.weeklySessionCount)",
                unit: "次",
                icon: "bed.double.fill"
            )
            statCard(
                title: "本周时长",
                value: tracker.weeklyDurationFormatted,
                unit: "",
                icon: "clock.fill"
            )
        }
    }

    private func statCard(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accentColor.opacity(0.5))
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))
            HStack(spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.medium)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(Theme.accentColor.opacity(0.4))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accentColor.opacity(0.06)))
    }

    // MARK: - Top Tracks

    private var topTracksSection: some View {
        let top = tracker.topTracks(names: nameResolver)

        return VStack(alignment: .leading, spacing: 12) {
            Label("最爱音效", systemImage: "heart.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Theme.accentColor.opacity(0.6))

            if top.isEmpty {
                Text("还没有播放记录\n开始播放一些音效吧")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accentColor.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(top.enumerated()), id: \.offset) { index, item in
                        topTrackRow(rank: index + 1, name: item.name, count: item.count)
                        if index < top.count - 1 {
                            Divider()
                                .background(Theme.accentColor.opacity(0.08))
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accentColor.opacity(0.05)))
            }

            // 累计总时长
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption)
                Text("累计收听 \(tracker.totalDurationFormatted)")
                    .font(.caption)
                Spacer()
            }
            .foregroundStyle(Theme.accentColor.opacity(0.4))
            .padding(.top, 4)
        }
    }

    private func topTrackRow(rank: Int, name: String, count: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(rank <= 3 ? Theme.accentColor : Theme.accentColor.opacity(0.35))
                .frame(width: 24)

            Text(name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            Text("\(count) 次")
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    NavigationStack {
        StatsView(nameResolver: { $0 })
    }
}
