//
//  SoundPlayerViewModel.swift
//  Unhurry
//

import SwiftUI
import Observation

/// 音效播放 ViewModel。
///
/// 桥接 `AudioService` 和 `SoundLibrary` 到 SwiftUI：
/// - 管理播放/停止状态
/// - 追踪活跃音轨及其独立音量
/// - 提供分类视图数据
@MainActor
@Observable
final class SoundPlayerViewModel {

    // MARK: - Published State

    /// 当前活跃（正在播放）的音效 ID 集合
    private(set) var activeTrackIds: Set<String> = []

    /// 每个音效的当前音量 (trackId → volume 0...1)
    private(set) var volumes: [String: Float] = [:]

    /// 是否至少有一个音效在播放
    var isAnythingPlaying: Bool { !activeTrackIds.isEmpty }

    // MARK: - Dependencies

    private let audioService: AudioServiceProtocol
    let tracks: [SoundTrack]

    // MARK: - Init

    init(audioService: AudioServiceProtocol, soundLibrary: SoundLibrary) {
        self.audioService = audioService
        self.tracks = soundLibrary.tracks
    }

    // MARK: - Computed

    /// 按分类分组
    var categorizedTracks: [(SoundCategory, [SoundTrack])] {
        Dictionary(grouping: tracks, by: \.category)
            .map { ($0.key, $0.value) }
            .sorted { $0.0.displayName < $1.0.displayName }
    }

    // MARK: - Actions

    /// 切换音效播放/停止。
    func toggleTrack(_ track: SoundTrack) {
        if activeTrackIds.contains(track.id) {
            stopTrack(track)
        } else {
            playTrack(track)
        }
    }

    /// 播放指定音效。
    func playTrack(_ track: SoundTrack) {
        do {
            try audioService.play(
                soundId: track.id,
                volume: track.defaultVolume,
                loop: track.isLoopable
            )
            activeTrackIds.insert(track.id)
            volumes[track.id] = track.defaultVolume
        } catch {
            print("⚠️ Failed to play \(track.name): \(error)")
        }
    }

    /// 停止指定音效。
    func stopTrack(_ track: SoundTrack) {
        audioService.stop(soundId: track.id)
        activeTrackIds.remove(track.id)
        volumes.removeValue(forKey: track.id)
    }

    /// 设置指定音效的音量。
    func setVolume(_ volume: Float, for trackId: String) {
        audioService.setVolume(volume, for: trackId)
        volumes[trackId] = volume
    }

    /// 停止所有音效。
    func stopAll() {
        audioService.stopAll()
        activeTrackIds.removeAll()
        volumes.removeAll()
    }

    /// 获取指定音效的名称。
    func name(for trackId: String) -> String {
        tracks.first { $0.id == trackId }?.name ?? trackId
    }
}
