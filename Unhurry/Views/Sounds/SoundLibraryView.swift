//
//  SoundLibraryView.swift
//  Unhurry
//

import SwiftUI
import UniformTypeIdentifiers

/// 音效库浏览视图——按分类展示可播放的音效。
struct SoundLibraryView: View {

    let viewModel: SoundPlayerViewModel

    @State private var showFileImporter = false
    @State private var trackToDelete: SoundTrack?

    private var accentColor: Color { Theme.accentColor }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 缓冲提示
                if viewModel.isSoundPreparing {
                    preparingBanner
                }

                // 导入按钮
                importButton

                // 收藏区
                if !viewModel.favoriteTracks.isEmpty {
                    categorySection(
                        title: "收藏",
                        icon: "heart.fill",
                        tracks: viewModel.favoriteTracks
                    )
                }

                ForEach(viewModel.categorizedTracks, id: \.0) { category, tracks in
                    categorySection(
                        title: category.displayName,
                        icon: category.iconName,
                        tracks: tracks
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio, .mp3, .wav],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    viewModel.importCustomTrack(from: url)
                }
            case .failure(let error):
                print("⚠️ File import failed: \(error)")
            }
        }
        .confirmationDialog(
            "删除自定义音效？",
            isPresented: Binding(
                get: { trackToDelete != nil },
                set: { if !$0 { trackToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let track = trackToDelete {
                    viewModel.deleteCustomTrack(track.id)
                }
                trackToDelete = nil
            }
            Button("取消", role: .cancel) { trackToDelete = nil }
        } message: {
            if let track = trackToDelete {
                Text("「\(track.name)」将被永久删除")
            }
        }
    }

    // MARK: - Import Button

    private var importButton: some View {
        Button(action: { showFileImporter = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.subheadline)
                Text("导入自定义音效")
                    .font(.subheadline)
                Spacer()
                Text("mp3 / wav / m4a")
                    .font(.caption2)
                    .foregroundStyle(accentColor.opacity(0.35))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accentColor.opacity(0.04))
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preparing Banner

    private var preparingBanner: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(accentColor)
            Text("即将开始播放……")
                .font(.caption)
                .foregroundStyle(Theme.accentColor.opacity(0.5))
            Spacer()
            Button("取消") {
                viewModel.cancelPreparation()
            }
            .font(.caption2)
            .foregroundStyle(accentColor.opacity(0.6))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor.opacity(0.06))
        )
    }

    // MARK: - Category Section

    private func categorySection(title: String, icon: String, tracks: [SoundTrack]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(accentColor.opacity(0.6))

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
        let isPending = viewModel.pendingTrackIds.contains(track.id)
        let isOn = isActive || isPending
        let isFav = viewModel.isFavorite(track.id)

        return ZStack {
            // 主按钮：播放/停止
            Button(action: { viewModel.toggleTrack(track) }) {
                VStack(spacing: 6) {
                    if isPending {
                        Image(systemName: "hourglass")
                            .font(.title)
                            .symbolEffect(.pulse)
                    } else {
                        Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    Text(track.name)
                        .font(.caption2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isOn
                            ? accentColor.opacity(isPending ? 0.12 : 0.2)
                            : accentColor.opacity(0.08)
                        )
                )
                .scaleEffect(isOn ? 0.96 : 1.0)
                .animation(.bouncy(duration: 0.3), value: isOn)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(isActive ? .stop : .start, trigger: isActive)

            // 收藏按钮（覆盖在右上角）
            Button(action: { viewModel.toggleFavorite(track.id) }) {
                Image(systemName: isFav ? "heart.fill" : "heart")
                    .font(.system(size: 12))
                    .foregroundStyle(isFav ? Color.red : accentColor.opacity(0.3))
                    .padding(8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFav ? "取消收藏\(track.name)" : "收藏\(track.name)")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .contextMenu {
            if track.category == .custom {
                Button(role: .destructive) {
                    trackToDelete = track
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
}
