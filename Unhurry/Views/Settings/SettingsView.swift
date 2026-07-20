//
//  SettingsView.swift
//  Unhurry
//

import SwiftUI

/// 设置页面：默认音量、缓冲时长、主题切换、使用统计。
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("defaultVolume") private var defaultVolume: Double = 0.5
    @AppStorage("bufferDuration") private var bufferDuration: Double = 3.0
    @AppStorage("accentTheme") private var accentTheme: String = "gold"
    @AppStorage("useBlackBackground") private var useBlackBackground: Bool = false

    let nameResolver: (String) -> String
    let presets: [MixPreset]

    @State private var reminderOn = Theme.reminderEnabled
    @State private var reminderTime = Theme.reminderDate
    @State private var reminderPresetId = Theme.reminderPresetId ?? ""
    @State private var healthSync = Theme.healthSyncEnabled

    var body: some View {
        ZStack {
            (useBlackBackground ? Color(red: 0.05, green: 0.05, blue: 0.05) : Theme.bgColor).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    statsSection
                    reminderSection
                    volumeSection
                    bufferSection
                    accentSection
                    backgroundSection
                    healthSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .foregroundStyle(Theme.accentColor)
        .preferredColorScheme(.dark)
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { dismiss() }
                    .foregroundStyle(Theme.accentColor)
            }
        }
        .onChange(of: reminderOn) { _, _ in saveReminder() }
        .onChange(of: reminderTime) { _, _ in saveReminder() }
        .onChange(of: reminderPresetId) { _, _ in saveReminder() }
        .onChange(of: healthSync) { _, newVal in
            Theme.healthSyncEnabled = newVal
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        NavigationLink(destination: StatsView(nameResolver: nameResolver)) {
            HStack {
                Label("使用统计", systemImage: "chart.bar.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.accentColor.opacity(0.4))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accentColor.opacity(0.05)))
        }
    }

    // MARK: - Default Volume

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("默认音量", icon: "speaker.wave.2.fill")
            sectionDescription("新播放音效的初始音量（已播放音效不受影响）")

            HStack {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.accentColor.opacity(0.4))
                Slider(value: $defaultVolume, in: 0...1)
                    .tint(Theme.accentColor)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.accentColor.opacity(0.4))
            }

            Text("\(Int(defaultVolume * 100))%")
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accentColor.opacity(0.05)))
    }

    // MARK: - Buffer Duration

    private var bufferSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("缓冲时长", icon: "timer")
            sectionDescription("点击音效后等待多久开始播放")

            HStack(spacing: 10) {
                ForEach(Theme.bufferOptions, id: \.1) { name, seconds in
                    Button(action: { bufferDuration = seconds }) {
                        Text(name)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                bufferDuration == seconds
                                    ? Theme.accentColor.opacity(0.2)
                                    : Theme.accentColor.opacity(0.06)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accentColor.opacity(0.05)))
    }

    // MARK: - Accent Color

    private var accentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("强调色", icon: "paintpalette.fill")
            sectionDescription("文字和图标的色调")

            HStack(spacing: 12) {
                ForEach(Theme.Accent.allCases, id: \.rawValue) { theme in
                    Button(action: { accentTheme = theme.rawValue }) {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(theme.color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    accentTheme == theme.rawValue
                                        ? Circle().stroke(Theme.accentColor, lineWidth: 2)
                                        : nil
                                )
                            Text(theme.displayName)
                                .font(.caption2)
                                .foregroundStyle(Theme.accentColor.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accentColor.opacity(0.05)))
    }

    // MARK: - Background

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("背景模式", icon: "moon.fill")
            sectionDescription("纯黑背景更省电，适合 OLED 屏幕夜间使用")

            Toggle(isOn: $useBlackBackground) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OLED 纯黑背景")
                        .font(.subheadline)
                    Text("暮色紫 → 纯黑")
                        .font(.caption)
                        .foregroundStyle(Theme.accentColor.opacity(0.4))
                }
            }
            .tint(Theme.accentColor)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accentColor.opacity(0.05)))
    }

    // MARK: - Health

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("健康同步", icon: "heart.fill")
            sectionDescription("将收听/冥想/呼吸时间自动记录为 Apple 健康中的正念分钟数")

            Toggle(isOn: $healthSync) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("同步到 Apple 健康")
                        .font(.subheadline)
                    Text("需在系统健康 App 中授权")
                        .font(.caption)
                        .foregroundStyle(Theme.accentColor.opacity(0.4))
                }
            }
            .tint(Theme.accentColor)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accentColor.opacity(0.05)))
    }

    // MARK: - Bedtime Reminder

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("就寝提醒", icon: "bed.double.fill")
            sectionDescription("每晚定时推送，点按通知一键启动预设")

            Toggle(isOn: $reminderOn) {
                Text("开启就寝提醒")
                    .font(.subheadline)
            }
            .tint(Theme.accentColor)

            if reminderOn {
                Divider().background(Theme.accentColor.opacity(0.1))

                DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)

                if !presets.isEmpty {
                    Picker("启动预设", selection: $reminderPresetId) {
                        Text("不选择预设").tag("")
                        ForEach(presets) { preset in
                            Text(preset.name).tag(preset.id.uuidString)
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    Text("暂无预设，请先在音效页面保存混音组合")
                        .font(.caption)
                        .foregroundStyle(Theme.accentColor.opacity(0.4))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accentColor.opacity(0.05)))
    }

    private func saveReminder() {
        Theme.reminderEnabled = reminderOn
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        Theme.reminderHour = comps.hour ?? 22
        Theme.reminderMinute = comps.minute ?? 0
        Theme.reminderPresetId = reminderPresetId.isEmpty ? nil : reminderPresetId
        ReminderService.reschedule()
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline)
            .fontWeight(.medium)
    }

    private func sectionDescription(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Theme.accentColor.opacity(0.4))
    }
}

#Preview {
    NavigationStack {
        SettingsView(nameResolver: { $0 }, presets: [])
    }
}
