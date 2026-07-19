//
//  SoundLibraryView.swift
//  Unhurry
//

import SwiftUI

/// 音效库浏览视图——按分类展示可播放的音效。
struct SoundLibraryView: View {

    let viewModel: SoundPlayerViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.categorizedTracks, id: \.0) { category, tracks in
                    categorySection(category: category, tracks: tracks)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Category Section

    private func categorySection(category: SoundCategory, tracks: [SoundTrack]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(category.displayName, systemImage: category.iconName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100), spacing: 12)],
                spacing: 12
            ) {
                ForEach(tracks) { track in
                    soundButton(for: track)
                }
            }
        }
    }

    // MARK: - Sound Button

    private func soundButton(for track: SoundTrack) -> some View {
        let isActive = viewModel.activeTrackIds.contains(track.id)

        return Button(action: { viewModel.toggleTrack(track) }) {
            VStack(spacing: 6) {
                Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title)
                Text(track.name)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive
                        ? Color(red: 0.941, green: 0.902, blue: 0.824).opacity(0.2)
                        : Color(red: 0.941, green: 0.902, blue: 0.824).opacity(0.08)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
