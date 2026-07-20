//
//  RitualPresetView.swift
//  Unhurry
//

import SwiftUI

/// 入睡仪式选择页——展示内置仪式模板 + 用户自定义仪式。
struct RitualPresetView: View {

    let playerVM: SoundPlayerViewModel
    let timerVM: TimerViewModel

    @AppStorage("useBlackBackground") private var useBlackBg = false
    private var accentColor: Color { Theme.accentColor }

    @State private var customRituals: [SleepRitual] = []
    @State private var showBuilder = false
    @State private var editingRitual: SleepRitual?
    @State private var deletingRitual: SleepRitual?

    private let presets = SleepRitual.presets

    var body: some View {
        ZStack {
            (useBlackBg ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("选择一个仪式，然后闭上眼睛，把一切交给它")
                        .font(.caption)
                        .foregroundStyle(accentColor.opacity(0.45))
                        .padding(.bottom, 4)

                    // 内置仪式
                    ForEach(presets) { ritual in
                        ritualCard(ritual)
                    }

                    // 自定义仪式
                    if !customRituals.isEmpty {
                        sectionDivider("我的仪式")

                        ForEach(customRituals) { ritual in
                            customRitualCard(ritual)
                        }
                    } else {
                        EmptyStateView(
                            icon: "slider.horizontal.3",
                            title: "还没有自定义仪式",
                            subtitle: "你可以自由搭配呼吸、音效和定时，打造专属的入睡流程",
                            actionLabel: "创建第一个",
                            action: {
                                editingRitual = nil
                                showBuilder = true
                            }
                        )
                    }

                    // 创建按钮
                    if !customRituals.isEmpty {
                        createButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .foregroundStyle(accentColor)
        .navigationTitle("入睡仪式")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { customRituals = SleepRitual.loadCustom() }
        .sheet(isPresented: $showBuilder) {
            NavigationStack {
                RitualBuilderView(
                    playerVM: playerVM,
                    existingRitual: editingRitual,
                    onSave: { ritual in
                        var customs = SleepRitual.loadCustom()
                        if let idx = customs.firstIndex(where: { $0.id == ritual.id }) {
                            customs[idx] = ritual
                        } else {
                            customs.append(ritual)
                        }
                        SleepRitual.saveCustom(customs)
                        customRituals = customs
                    }
                )
            }
        }
        .confirmationDialog(
            "删除「\(deletingRitual?.name ?? "")」？",
            isPresented: .constant(deletingRitual != nil)
        ) {
            Button("删除", role: .destructive) {
                if let ritual = deletingRitual {
                    customRituals.removeAll { $0.id == ritual.id }
                    SleepRitual.saveCustom(customRituals)
                }
                deletingRitual = nil
            }
            Button("取消", role: .cancel) { deletingRitual = nil }
        } message: {
            Text("此操作无法撤销")
        }
    }

    // MARK: - Section Divider

    private func sectionDivider(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(accentColor.opacity(0.5))
            Rectangle()
                .fill(accentColor.opacity(0.1))
                .frame(height: 1)
        }
        .padding(.top, 8)
    }

    // MARK: - Ritual Card (preset)

    private func ritualCard(_ ritual: SleepRitual) -> some View {
        NavigationLink(destination: {
            SleepRitualView(
                ritual: ritual,
                viewModel: SleepRitualViewModel(playerVM: playerVM, timerVM: timerVM)
            )
        }) {
            ritualCardContent(ritual)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ritual Card (custom, with edit/delete)

    private func customRitualCard(_ ritual: SleepRitual) -> some View {
        NavigationLink(destination: {
            SleepRitualView(
                ritual: ritual,
                viewModel: SleepRitualViewModel(playerVM: playerVM, timerVM: timerVM)
            )
        }) {
            ritualCardContent(ritual)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                editingRitual = ritual
                showBuilder = true
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            Button(role: .destructive) {
                deletingRitual = ritual
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    // MARK: - Card Content (shared)

    private func ritualCardContent(_ ritual: SleepRitual) -> some View {
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

    // MARK: - Create Button

    private var createButton: some View {
        Button(action: {
            editingRitual = nil
            showBuilder = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.subheadline)
                Text("创建自定义仪式")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(accentColor.opacity(0.3))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accentColor.opacity(0.04))
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}
