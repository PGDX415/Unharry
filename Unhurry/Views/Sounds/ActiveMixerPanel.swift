//
//  ActiveMixerPanel.swift
//  Unhurry
//

import SwiftUI

/// 混音面板——展示活跃音轨音量滑块 + 保存/加载预设。
struct ActiveMixerPanel: View {

    let viewModel: SoundPlayerViewModel

    @State private var showSaveAlert = false
    @State private var presetName = ""
    @State private var presetToDelete: MixPreset?

    private var accentColor: Color { Theme.accentColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .background(accentColor.opacity(0.2))

            // ── 预设快捷栏（始终可见） ──
            if !viewModel.presets.isEmpty {
                presetBar
            }

            // ── 活跃/等待中音轨 ──
            if viewModel.isAnythingPlaying || viewModel.isSoundPreparing {
                activeMixerSection
            }
        }
        .alert("保存组合", isPresented: $showSaveAlert) {
            TextField("组合名称", text: $presetName)
            Button("取消", role: .cancel) { presetName = "" }
            Button("保存") {
                let name = presetName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    viewModel.saveCurrentMix(name: name)
                }
                presetName = ""
            }
        } message: {
            let count = viewModel.activeTrackIds.count
            Text("将当前 \(count) 个音效的组合保存为预设，下次一键召回。")
        }
        .confirmationDialog(
            "删除预设？",
            isPresented: Binding(
                get: { presetToDelete != nil },
                set: { if !$0 { presetToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let preset = presetToDelete {
                    viewModel.deletePreset(preset)
                }
                presetToDelete = nil
            }
            Button("取消", role: .cancel) { presetToDelete = nil }
        } message: {
            if let preset = presetToDelete {
                Text("确定删除「\(preset.name)」？此操作不可撤销。")
            }
        }
    }

    // MARK: - Preset Bar

    private var presetBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("我的组合", systemImage: "rectangle.stack.fill")
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.presets) { preset in
                        presetChip(preset)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 10)
    }

    private func presetChip(_ preset: MixPreset) -> some View {
        Button(action: { viewModel.loadPreset(preset) }) {
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 8))
                Text(preset.name)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(accentColor.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                presetToDelete = preset
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    // MARK: - Active Mixer

    private var activeMixerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    viewModel.isSoundPreparing ? "准备中" : "正在播放",
                    systemImage: viewModel.isSoundPreparing ? "hourglass" : "speaker.wave.2.fill"
                )
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.accentColor.opacity(0.5))

                Spacer()

                // 只有真正在播放时才能保存
                if viewModel.isAnythingPlaying {
                    Button(action: {
                        presetName = ""
                        showSaveAlert = true
                    }) {
                        Label("保存", systemImage: "square.and.arrow.down")
                            .font(.caption)
                            .foregroundStyle(accentColor.opacity(0.7))
                    }
                }

                Button(action: { viewModel.stopAll() }) {
                    Text("全部停止")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                }
            }

            // 等待中的音效（缓冲期间）
            ForEach(Array(viewModel.pendingTrackIds), id: \.self) { trackId in
                pendingRow(for: trackId)
            }

            // 活跃音效
            ForEach(Array(viewModel.activeTrackIds), id: \.self) { trackId in
                volumeRow(for: trackId)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Pending Row

    private func pendingRow(for trackId: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "hourglass")
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))
                .frame(width: 20)

            Text(viewModel.name(for: trackId))
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))

            Spacer()

            ProgressView()
                .scaleEffect(0.6)
                .tint(accentColor)
        }
    }

    // MARK: - Volume Row

    private func volumeRow(for trackId: String) -> some View {
        let name = viewModel.name(for: trackId)
        let volume = viewModel.volumes[trackId] ?? 0.5

        return HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))
                .frame(width: 20)

            Text(name)
                .font(.caption)
                .frame(width: 50, alignment: .leading)
                .lineLimit(1)

            Slider(value: Binding(
                get: { Double(volume) },
                set: { viewModel.setVolume(Float($0), for: trackId) }
            ), in: 0...1)
                .tint(accentColor)

            Text(String(format: "%.0f%%", volume * 100))
                .font(.caption2)
                .foregroundStyle(Theme.accentColor.opacity(0.5))
                .frame(width: 36, alignment: .trailing)
        }
    }
}
