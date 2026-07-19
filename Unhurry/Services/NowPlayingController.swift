//
//  NowPlayingController.swift
//  Unhurry
//

import MediaPlayer
import AVFoundation

/// 锁屏 / 控制中心「正在播放」信息与远程指令处理。
///
/// 负责：
/// - 设置 MPNowPlayingInfoCenter（锁屏显示的歌曲信息）
/// - 响应 MPRemoteCommandCenter（播放/暂停/上下曲）
final class NowPlayingController {

    // MARK: - Callbacks

    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?
    var onTogglePlayPause: (() -> Void)?
    var onNextTrack: (() -> Void)?
    var onPreviousTrack: (() -> Void)?

    // MARK: - Init

    init() {
        configureRemoteCommands()
    }

    // MARK: - Public

    /// 更新锁屏显示信息。
    func updateNowPlaying(
        title: String,
        artist: String,
        isPlaying: Bool,
        elapsed: TimeInterval = 0,
        duration: TimeInterval = 0
    ) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]

        if elapsed > 0 {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        }
        if duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// 清除锁屏信息（无音效播放时）。
    func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Private: Remote Commands

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        // 播放
        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            self?.onPlay?()
            return .success
        }

        // 暂停
        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            self?.onPause?()
            return .success
        }

        // 播放/暂停切换
        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.onTogglePlayPause?()
            return .success
        }

        // 下一首
        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.onNextTrack?()
            return .success
        }

        // 上一首
        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.onPreviousTrack?()
            return .success
        }

        // 禁用不需要的命令
        center.changePlaybackPositionCommand.isEnabled = false
        center.seekForwardCommand.isEnabled = false
        center.seekBackwardCommand.isEnabled = false
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
        center.ratingCommand.isEnabled = false
        center.likeCommand.isEnabled = false
        center.dislikeCommand.isEnabled = false
        center.bookmarkCommand.isEnabled = false
    }
}
