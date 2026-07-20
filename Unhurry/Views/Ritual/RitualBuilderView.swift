//
//  RitualBuilderView.swift
//  Unhurry
//

import SwiftUI

/// 自定义入睡仪式编辑器。
struct RitualBuilderView: View {

    let playerVM: SoundPlayerViewModel
    let existingRitual: SleepRitual?  // nil = 新建
    var onSave: (SleepRitual) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("useBlackBackground") private var useBlackBg = false
    private var accentColor: Color { Theme.accentColor }

    // MARK: - State

    @State private var ritualName: String = ""
    @State private var breathMinutes: Int = 2
    @State private var selectedTrackIds: Set<String> = []
    @State private var timerMinutes: Int = 20

    private let breathOptions = [1, 2, 3, 5]
    private let timerOptions = [10, 15, 20, 25, 30, 45, 60]

    var body: some View {
        ZStack {
            (useBlackBg ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    nameSection
                    breathSection
                    soundsSection
                    timerSection
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .foregroundStyle(accentColor)
        .navigationTitle(existingRitual == nil ? "创建仪式" : "编辑仪式")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadExisting() }
    }

    // MARK: - Load Existing

    private func loadExisting() {
        guard let r = existingRitual else { return }
        ritualName = r.name
        for step in r.steps {
            switch step {
            case .breath(let d):
                breathMinutes = Int(d / 60)
            case .sounds(let ids):
                selectedTrackIds = Set(ids)
            case .timer(let d):
                timerMinutes = Int(d / 60)
            }
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("仪式名称", icon: "pencil")
            TextField("例如：我的睡前流程", text: $ritualName)
                .font(.subheadline)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(0.08))
                )
        }
    }

    // MARK: - Breath

    private var breathSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("呼吸放松", icon: "wind")
            sectionDescription("仪式开始时的呼吸引导时长")

            HStack(spacing: 8) {
                ForEach(breathOptions, id: \.self) { min in
                    Button(action: { breathMinutes = min }) {
                        Text("\(min) 分钟")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(breathMinutes == min
                                        ? accentColor.opacity(0.2)
                                        : accentColor.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Sounds

    private var soundsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("播放音效", icon: "speaker.wave.2.fill")
            sectionDescription("选择 2~4 个音效组合（多选）")

            let soundTracks = playerVM.tracks.filter { $0.category != .story }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 90), spacing: 8)],
                spacing: 8
            ) {
                ForEach(soundTracks) { track in
                    let isSelected = selectedTrackIds.contains(track.id)
                    Button(action: {
                        if isSelected {
                            selectedTrackIds.remove(track.id)
                        } else if selectedTrackIds.count < 4 {
                            selectedTrackIds.insert(track.id)
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.subheadline)
                                .foregroundStyle(isSelected ? accentColor : accentColor.opacity(0.3))
                            Text(track.name)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? accentColor.opacity(0.18) : accentColor.opacity(0.06))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Timer

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("定时关闭", icon: "timer")
            sectionDescription("音效播放多久后渐弱停止")

            HStack(spacing: 8) {
                ForEach(timerOptions, id: \.self) { min in
                    Button(action: { timerMinutes = min }) {
                        Text("\(min) 分")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(timerMinutes == min
                                        ? accentColor.opacity(0.2)
                                        : accentColor.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button(action: {
            let name = ritualName.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, !selectedTrackIds.isEmpty else { return }

            let trackIds = Array(selectedTrackIds)
            let steps: [RitualStep] = [
                .breath(duration: TimeInterval(breathMinutes * 60)),
                .sounds(trackIds: trackIds),
                .timer(duration: TimeInterval(timerMinutes * 60)),
            ]

            // 生成描述
            let desc = steps.map { step -> String in
                switch step {
                case .breath(let d): return "\(Int(d) / 60) 分钟呼吸"
                case .sounds(let ids): return ids.compactMap { id in playerVM.tracks.first(where: { $0.id == id })?.name }.joined(separator: " + ")
                case .timer(let d): return "\(Int(d) / 60) 分钟定时"
                }
            }.joined(separator: " → ")

            let ritual = SleepRitual(
                id: existingRitual?.id ?? UUID(),
                name: name,
                description: desc,
                icon: "slider.horizontal.3",
                steps: steps,
                isCustom: true
            )
            onSave(ritual)
            dismiss()
        }) {
            HStack {
                Image(systemName: "checkmark")
                Text("保存仪式")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(canSave ? accentColor.opacity(0.15) : accentColor.opacity(0.05))
            )
            .foregroundStyle(canSave ? accentColor : accentColor.opacity(0.3))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    private var canSave: Bool {
        !ritualName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedTrackIds.isEmpty
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(accentColor.opacity(0.65))
    }

    private func sectionDescription(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(accentColor.opacity(0.4))
    }
}
