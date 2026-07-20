//
//  SoundPlayerViewModel.swift
//  Unhurry
//

import SwiftUI
import Observation
import MediaPlayer
import WidgetKit

/// 音效播放 ViewModel。
///
/// 桥接 `AudioService` 和 `SoundLibrary` 到 SwiftUI：
/// - 管理播放/停止状态
/// - 追踪活跃音轨及其独立音量
/// - 提供分类视图数据
/// - 管理锁屏控制（NowPlaying + RemoteCommand）
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

    /// 播放前准备缓冲中
    private(set) var isSoundPreparing = false

    /// 等待缓冲结束后播放的音效 ID（含组合加载）
    private(set) var pendingTrackIds: Set<String> = []

    /// 所有已播放 + 等待中的音效（用于 UI 高亮）
    var allActiveOrPendingIds: Set<String> { activeTrackIds.union(pendingTrackIds) }

    /// 是否被系统远程暂停（锁屏/控制中心）
    private(set) var isSystemPaused = false

    /// 已保存的混音预设
    private(set) var presets: [MixPreset] = []

    /// 收藏的音效 ID 集合
    private(set) var favoriteTrackIDs: Set<String> = []

    /// 收藏的音效列表
    var favoriteTracks: [SoundTrack] {
        tracks.filter { favoriteTrackIDs.contains($0.id) }
    }

    // MARK: - Visualizer

    let visualizer = AudioVisualizerService()

    // MARK: - EQ & Reverb State

    /// 每个音效的低音增益 (trackId → dB, -12...+12)
    private(set) var bassGains: [String: Float] = [:]

    /// 每个音效的高音增益
    private(set) var trebleGains: [String: Float] = [:]

    /// 每个音效的混响湿/干比 (trackId → 0...100)
    private(set) var reverbMixes: [String: Float] = [:]

    /// 音效调节面板展开状态
    private(set) var expandedEQTrackIds: Set<String> = []

    // MARK: - Constants

    /// 音频播放前准备缓冲时间（秒）——优先读取用户设置
    static var soundPrepareDelay: TimeInterval {
        Theme.bufferDuration
    }

    // MARK: - Dependencies

    private let audioService: AudioServiceProtocol
    private let nowPlaying: NowPlayingController
    private let soundLibrary: SoundLibrary
    private(set) var tracks: [SoundTrack]

    // MARK: - Private: Preparation

    private var prepareTimer: Timer?
    private var pendingVolumes: [String: Float] = [:]

    // MARK: - Private: NowPlaying

    private var playbackStartDate: Date?
    private var nowPlayingTimer: Timer?
    /// 系统暂停前保存的音效快照，供恢复使用
    private var savedTrackIds: Set<String> = []
    private var savedVolumes: [String: Float] = [:]

    // MARK: - Persistence

    private static let presetsKey = "com.unhurry.mixpresets"
    private static let favoritesKey = "com.unhurry.favorites"

    // MARK: - Init

    init(
        audioService: AudioServiceProtocol,
        soundLibrary: SoundLibrary,
        nowPlayingController: NowPlayingController
    ) {
        self.audioService = audioService
        self.soundLibrary = soundLibrary
        self.tracks = soundLibrary.tracks
        self.nowPlaying = nowPlayingController
        loadPresetsFromDisk()
        loadFavoritesFromDisk()
        setupRemoteCommands()
    }

    // MARK: - Computed

    /// 按分类分组
    var categorizedTracks: [(SoundCategory, [SoundTrack])] {
        Dictionary(grouping: tracks, by: \.category)
            .map { ($0.key, $0.value) }
            .sorted { $0.0.displayName < $1.0.displayName }
    }

    // MARK: - Actions

    /// 切换音效播放/停止（3 秒缓冲后播放）。
    func toggleTrack(_ track: SoundTrack) {
        if activeTrackIds.contains(track.id) {
            // 已在播放 → 立即停止
            stopTrack(track)
        } else if pendingTrackIds.contains(track.id) {
            // 在等待队列中 → 取消
            cancelPendingTrack(track.id)
        } else {
            // 新音效 → 基础音量 × 全局默认音量
            let volume = track.defaultVolume * Float(Theme.defaultVolume)
            schedulePlay(trackId: track.id, volume: volume, loop: track.isLoopable)
        }
    }

    /// 直接播放指定音效（不经过缓冲，用于内部 flush）。
    private func executePlay(trackId: String, volume: Float, loop: Bool) {
        do {
            let wasEmpty = activeTrackIds.isEmpty
            try audioService.play(soundId: trackId, volume: volume, loop: loop)
            activeTrackIds.insert(trackId)
            volumes[trackId] = volume
            UsageTracker.shared.trackStarted(trackId)
            if wasEmpty {
                startVisualizer()
            }
        } catch {
            print("⚠️ Failed to play \(trackId): \(error)")
        }
    }

    /// 将音效加入等待队列，开始 3 秒缓冲计时。
    private func schedulePlay(trackId: String, volume: Float, loop: Bool) {
        pendingTrackIds.insert(trackId)
        pendingVolumes[trackId] = volume

        // 如果还没在倒计时，启动
        if prepareTimer == nil {
            isSoundPreparing = true
            prepareTimer = Timer.scheduledTimer(
                withTimeInterval: Self.soundPrepareDelay,
                repeats: false
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.flushPending()
                }
            }
            RunLoop.main.add(prepareTimer!, forMode: .common)
        }
        // loop 信息暂时存 volume 里，flush 时按 track 的 isLoopable 播
    }

    /// 缓冲结束，一次性播放所有等待中的音效。
    private func flushPending() {
        prepareTimer?.invalidate()
        prepareTimer = nil
        isSoundPreparing = false

        let ids = pendingTrackIds
        pendingTrackIds.removeAll()

        for trackId in ids {
            let volume = pendingVolumes[trackId] ?? 0.5
            pendingVolumes.removeValue(forKey: trackId)
            let loop = tracks.first { $0.id == trackId }?.isLoopable ?? true
            executePlay(trackId: trackId, volume: volume, loop: loop)
        }

        // 有音效开始播放 → 更新锁屏 + 保存用于 Siri 恢复
        if !activeTrackIds.isEmpty {
            startNowPlaying()
            saveLastActivePreset()
        }
    }

    /// 取消等待中的单个音效。
    private func cancelPendingTrack(_ trackId: String) {
        pendingTrackIds.remove(trackId)
        pendingVolumes.removeValue(forKey: trackId)
        if pendingTrackIds.isEmpty {
            cancelPreparation()
        }
    }

    /// 取消整个准备缓冲。
    func cancelPreparation() {
        prepareTimer?.invalidate()
        prepareTimer = nil
        isSoundPreparing = false
        pendingTrackIds.removeAll()
        pendingVolumes.removeAll()
    }

    /// 停止指定音效。
    func stopTrack(_ track: SoundTrack) {
        audioService.stop(soundId: track.id)
        activeTrackIds.remove(track.id)
        volumes.removeValue(forKey: track.id)
        bassGains.removeValue(forKey: track.id)
        trebleGains.removeValue(forKey: track.id)
        reverbMixes.removeValue(forKey: track.id)
        expandedEQTrackIds.remove(track.id)
        UsageTracker.shared.trackStopped(track.id)
        if activeTrackIds.isEmpty {
            clearNowPlaying()
            stopVisualizer()
        } else {
            saveLastActivePreset()
        }
    }

    /// 设置指定音效的音量。
    func setVolume(_ volume: Float, for trackId: String) {
        audioService.setVolume(volume, for: trackId)
        volumes[trackId] = volume
    }

    /// 停止所有音效 + 取消缓冲 + 清除锁屏。
    func stopAll() {
        cancelPreparation()
        audioService.stopAll()
        activeTrackIds.removeAll()
        volumes.removeAll()
        bassGains.removeAll()
        trebleGains.removeAll()
        reverbMixes.removeAll()
        expandedEQTrackIds.removeAll()
        UsageTracker.shared.allStopped()
        clearNowPlaying()
        stopVisualizer()
    }

    /// 获取指定音效的名称。
    func name(for trackId: String) -> String {
        tracks.first { $0.id == trackId }?.name ?? trackId
    }

    // MARK: - EQ

    func setBassGain(_ gain: Float, for trackId: String) {
        bassGains[trackId] = max(-12, min(12, gain))
        audioService.setEQ(for: trackId, bassGain: bassGains[trackId]!, trebleGain: trebleGains[trackId] ?? 0)
    }

    func setTrebleGain(_ gain: Float, for trackId: String) {
        trebleGains[trackId] = max(-12, min(12, gain))
        audioService.setEQ(for: trackId, bassGain: bassGains[trackId] ?? 0, trebleGain: trebleGains[trackId]!)
    }

    // MARK: - Reverb

    func setReverbMix(_ mix: Float, for trackId: String) {
        reverbMixes[trackId] = max(0, min(100, mix))
        audioService.setReverb(for: trackId, wetDryMix: reverbMixes[trackId]!)
    }

    // MARK: - Crossfade

    /// 交叉淡入淡出：oldTrackId → newTrack，duration 秒内完成。
    func crossfade(from oldTrackId: String, to newTrack: SoundTrack, duration: TimeInterval = 2.0) {
        // 确保新音效在播放，且已存在于 activeTrackIds
        guard activeTrackIds.contains(oldTrackId) else {
            // 旧音效不在播放 → 直接切换
            toggleTrack(newTrack)
            return
        }

        if !activeTrackIds.contains(newTrack.id) {
            // 以 0 音量启动新音效
            executePlay(trackId: newTrack.id, volume: 0.01, loop: newTrack.isLoopable)
            volumes[newTrack.id] = 0.01
        }

        audioService.crossfade(
            from: oldTrackId,
            to: newTrack.id,
            duration: duration
        ) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.activeTrackIds.remove(oldTrackId)
                self.volumes.removeValue(forKey: oldTrackId)
                self.bassGains.removeValue(forKey: oldTrackId)
                self.trebleGains.removeValue(forKey: oldTrackId)
                self.reverbMixes.removeValue(forKey: oldTrackId)
                UsageTracker.shared.trackStopped(oldTrackId)
                if self.activeTrackIds.isEmpty {
                    self.clearNowPlaying()
                    self.stopVisualizer()
                }
            }
        }
    }

    func toggleEQExpanded(_ trackId: String) {
        if expandedEQTrackIds.contains(trackId) {
            expandedEQTrackIds.remove(trackId)
        } else {
            expandedEQTrackIds.insert(trackId)
        }
    }

    // MARK: - Presets

    /// 将当前活跃音效组合保存为预设。
    func saveCurrentMix(name: String) {
        guard !activeTrackIds.isEmpty else { return }
        let preset = MixPreset(
            name: name,
            trackIds: Array(activeTrackIds),
            volumes: volumes.filter { activeTrackIds.contains($0.key) }
        )
        presets.append(preset)
        persistPresets()
    }

    /// 加载预设：停止所有 → 3 秒缓冲 → 播放预设中的所有音效。
    func loadPreset(_ preset: MixPreset) {
        stopAll()
        for trackId in preset.trackIds {
            let volume = preset.volumes[trackId] ?? 0.5
            schedulePlay(trackId: trackId, volume: volume, loop: true)
        }
    }

    /// 删除指定预设。
    func deletePreset(_ preset: MixPreset) {
        presets.removeAll { $0.id == preset.id }
        persistPresets()
    }

    /// Siri / Shortcuts 触发：恢复上次使用的预设，或加载第一个预设，或默认轻雨。
    func loadLastOrDefaultPreset() {
        // 1. 尝试恢复上次保存的活跃音效组合
        if let savedIds = lastActivePresetTrackIds(), !savedIds.isEmpty {
            stopAll()
            for trackId in savedIds {
                let vol = lastActivePresetVolumes()[trackId] ?? 0.5
                schedulePlay(trackId: trackId, volume: vol, loop: true)
            }
            // 清理旧记录，下次使用新的活跃组合
            clearLastActivePreset()
            return
        }

        // 2. 尝试加载第一个已保存的预设
        if let firstPreset = presets.first {
            loadPreset(firstPreset)
            return
        }

        // 3. 默认：播放轻雨
        stopAll()
        let defaultTrack = tracks.first { $0.id == "ai_rain_light" }
            ?? tracks.first { $0.category == .rain }
            ?? tracks.first
        if let track = defaultTrack {
            toggleTrack(track)
        }
    }

    /// 持久化当前活跃音效组合（供 Siri Intent 恢复）。
    func saveLastActivePreset() {
        guard !activeTrackIds.isEmpty else { return }
        let defaults = UserDefaults.standard
        defaults.set(Array(activeTrackIds), forKey: Self.lastActiveTrackIdsKey)
        // 保存音量映射为 JSON 字符串
        if let data = try? JSONEncoder().encode(volumes) {
            defaults.set(data, forKey: Self.lastActiveVolumesKey)
        }
    }

    private static let lastActiveTrackIdsKey = "com.unhurry.lastActiveTrackIds"
    private static let lastActiveVolumesKey = "com.unhurry.lastActiveVolumes"

    private func lastActivePresetTrackIds() -> [String]? {
        UserDefaults.standard.stringArray(forKey: Self.lastActiveTrackIdsKey)
    }

    private func lastActivePresetVolumes() -> [String: Float] {
        guard let data = UserDefaults.standard.data(forKey: Self.lastActiveVolumesKey),
              let dict = try? JSONDecoder().decode([String: Float].self, from: data)
        else { return [:] }
        return dict
    }

    private func clearLastActivePreset() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.lastActiveTrackIdsKey)
        defaults.removeObject(forKey: Self.lastActiveVolumesKey)
    }

    // MARK: - NowPlaying & Remote Commands

    private func setupRemoteCommands() {
        nowPlaying.onPlay = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleRemotePlay()
            }
        }
        nowPlaying.onPause = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleRemotePause()
            }
        }
        nowPlaying.onTogglePlayPause = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleRemoteToggle()
            }
        }
        nowPlaying.onNextTrack = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleRemoteNext()
            }
        }
        nowPlaying.onPreviousTrack = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleRemotePrevious()
            }
        }
    }

    private func startNowPlaying() {
        let names = activeTrackIds.compactMap { name(for: $0) }
        let title = names.isEmpty ? "闲眠" : names.joined(separator: " · ")
        nowPlaying.updateNowPlaying(
            title: title,
            artist: "闲眠",
            isPlaying: true
        )
        playbackStartDate = Date()
        isSystemPaused = false
        startNowPlayingTimer()
    }

    private func clearNowPlaying() {
        nowPlaying.clear()
        stopNowPlayingTimer()
        playbackStartDate = nil
        savedTrackIds.removeAll()
        savedVolumes.removeAll()
        isSystemPaused = false
    }

    private func startNowPlayingTimer() {
        stopNowPlayingTimer()
        nowPlayingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNowPlayingElapsed()
            }
        }
        RunLoop.main.add(nowPlayingTimer!, forMode: .common)
    }

    private func stopNowPlayingTimer() {
        nowPlayingTimer?.invalidate()
        nowPlayingTimer = nil
    }

    private func refreshNowPlayingElapsed() {
        guard let start = playbackStartDate, !activeTrackIds.isEmpty else { return }
        let names = activeTrackIds.compactMap { name(for: $0) }
        let title = names.isEmpty ? "闲眠" : names.joined(separator: " · ")
        nowPlaying.updateNowPlaying(
            title: title,
            artist: "闲眠",
            isPlaying: !isSystemPaused,
            elapsed: Date().timeIntervalSince(start)
        )
    }

    // MARK: - Remote Command Handlers

    private func handleRemotePlay() {
        guard isSystemPaused, !savedTrackIds.isEmpty else { return }
        // 恢复之前被远程暂停的音效
        for trackId in savedTrackIds {
            try? audioService.resume(soundId: trackId)
        }
        activeTrackIds = savedTrackIds
        volumes = savedVolumes
        isSystemPaused = false
        startNowPlaying()
        startVisualizer()
    }

    private func handleRemotePause() {
        guard !activeTrackIds.isEmpty, !isSystemPaused else { return }
        savedTrackIds = activeTrackIds
        savedVolumes = volumes
        for trackId in activeTrackIds {
            audioService.pause(soundId: trackId)
        }
        isSystemPaused = true
        stopNowPlayingTimer()
        // 更新锁屏为暂停状态
        let names = activeTrackIds.compactMap { name(for: $0) }
        let title = names.isEmpty ? "闲眠" : names.joined(separator: " · ")
        nowPlaying.updateNowPlaying(title: title, artist: "闲眠", isPlaying: false)
    }

    private func handleRemoteToggle() {
        if isSystemPaused {
            handleRemotePlay()
        } else if !activeTrackIds.isEmpty {
            handleRemotePause()
        }
    }

    private func handleRemoteNext() {
        guard !presets.isEmpty else { return }
        // 找当前匹配的预设索引，跳到下一个
        let currentIds = activeTrackIds
        let currentIndex = presets.firstIndex { Set($0.trackIds) == currentIds } ?? -1
        let nextIndex = (currentIndex + 1) % presets.count
        loadPreset(presets[nextIndex])
    }

    private func handleRemotePrevious() {
        guard !presets.isEmpty else { return }
        let currentIds = activeTrackIds
        let currentIndex = presets.firstIndex { Set($0.trackIds) == currentIds } ?? presets.count
        let prevIndex = (currentIndex - 1 + presets.count) % presets.count
        loadPreset(presets[prevIndex])
    }

    // MARK: - Visualizer

    private func startVisualizer() {
        guard let mixer = (audioService as? AudioService)?.mainMixerNode else {
            visualizer.start(on: audioService.mainMixerNode)
            return
        }
        visualizer.start(on: mixer)
    }

    private func stopVisualizer() {
        visualizer.stop()
    }

    // MARK: - Private: Persistence

    /// App Group 共享 UserDefaults（Widget 可读取）
    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: "group.com.gongdexin.paul.Unhurry") ?? .standard
    }

    private func loadPresetsFromDisk() {
        let defaults = Self.sharedDefaults
        if let data = defaults.data(forKey: Self.presetsKey) {
            decodePresets(from: data)
        } else if let data = UserDefaults.standard.data(forKey: Self.presetsKey) {
            // 从旧存储迁移到 App Group
            decodePresets(from: data)
            defaults.set(data, forKey: Self.presetsKey)
        }
    }

    private func decodePresets(from data: Data) {
        do {
            presets = try JSONDecoder().decode([MixPreset].self, from: data)
        } catch {
            print("⚠️ Failed to load presets: \(error)")
        }
    }

    private func persistPresets() {
        do {
            let data = try JSONEncoder().encode(presets)
            Self.sharedDefaults.set(data, forKey: Self.presetsKey)
            // 通知 Widget 刷新
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("⚠️ Failed to save presets: \(error)")
        }
    }

    // MARK: - Custom Tracks

    /// 导入用户自定义音效（从 document picker URL）。
    func importCustomTrack(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("⚠️ Cannot access security-scoped resource")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        if let _ = soundLibrary.importCustomTrack(from: url, into: audioService) {
            tracks = soundLibrary.tracks
        }
    }

    /// 删除用户自定义音效。
    func deleteCustomTrack(_ trackId: String) {
        // 如果正在播放，先停止
        if activeTrackIds.contains(trackId) {
            audioService.stop(soundId: trackId)
            activeTrackIds.remove(trackId)
            volumes.removeValue(forKey: trackId)
        }
        soundLibrary.deleteCustomTrack(trackId)
        tracks = soundLibrary.tracks
    }

    // MARK: - Favorites

    /// 切换音效的收藏状态。
    func toggleFavorite(_ trackId: String) {
        if favoriteTrackIDs.contains(trackId) {
            favoriteTrackIDs.remove(trackId)
        } else {
            favoriteTrackIDs.insert(trackId)
        }
        persistFavorites()
    }

    /// 是否已收藏指定音效。
    func isFavorite(_ trackId: String) -> Bool {
        favoriteTrackIDs.contains(trackId)
    }

    private func loadFavoritesFromDisk() {
        let defaults = Self.sharedDefaults
        if let ids = defaults.stringArray(forKey: Self.favoritesKey) {
            favoriteTrackIDs = Set(ids)
        } else if let ids = UserDefaults.standard.stringArray(forKey: Self.favoritesKey) {
            // 从旧存储迁移
            favoriteTrackIDs = Set(ids)
            defaults.set(ids, forKey: Self.favoritesKey)
        }
    }

    private func persistFavorites() {
        Self.sharedDefaults.set(Array(favoriteTrackIDs), forKey: Self.favoritesKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
