//
//  ActiveMixerPanel.swift
//  Unhurry
//

import SwiftUI

/// 混音面板——展示当前活跃音轨及其独立音量滑块。
struct ActiveMixerPanel: View {

    let viewModel: SoundPlayerViewModel

    var body: some View {
        if viewModel.isAnythingPlaying {
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                    .background(Color(red: 0.941, green: 0.902, blue: 0.824).opacity(0.2))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("正在播放", systemImage: "speaker.wave.2.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button(action: { viewModel.stopAll() }) {
                            Text("全部停止")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.8))
                        }
                    }

                    ForEach(Array(viewModel.activeTrackIds), id: \.self) { trackId in
                        volumeRow(for: trackId)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
        }
    }

    // MARK: - Volume Row

    private func volumeRow(for trackId: String) -> some View {
        let name = viewModel.name(for: trackId)
        let volume = viewModel.volumes[trackId] ?? 0.5

        return HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(name)
                .font(.caption)
                .frame(width: 50, alignment: .leading)
                .lineLimit(1)

            Slider(value: Binding(
                get: { Double(volume) },
                set: { viewModel.setVolume(Float($0), for: trackId) }
            ), in: 0...1)
                .tint(Color(red: 0.941, green: 0.902, blue: 0.824))

            Text(String(format: "%.0f%%", volume * 100))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
    }
}
