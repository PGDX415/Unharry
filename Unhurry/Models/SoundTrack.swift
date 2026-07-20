//
//  SoundTrack.swift
//  Unhurry
//

import Foundation

/// 表示一个可播放的音效资源。
///
/// 每个音效对应一个音频文件，在 App 中以唯一 `id` 标识。
/// `SoundTrack` 只是元数据描述，实际音频数据由 `AudioService` 管理。
struct SoundTrack: Identifiable, Hashable {
    /// 唯一标识符，例如 "rain_light", "ocean_waves"
    let id: String

    /// 显示名称，例如 "轻雨", "海浪"
    let name: String

    /// 所属分类（雨声、自然、冥想等）
    let category: SoundCategory

    /// 音频文件名（不含扩展名），例如 "rain_light_v1"
    let fileName: String

    /// 音频文件扩展名，例如 "m4a"
    let fileExtension: String

    /// 默认音量 (0.0 ~ 1.0)
    let defaultVolume: Float

    /// 是否为循环播放（白噪音类一般为 true，故事/冥想类为 false）
    let isLoopable: Bool

    /// 音频时长（秒），加载后填充；-1 表示未知
    var duration: TimeInterval = -1

    /// 自定义音效的本地文件 URL（Bundle 内置音效为 nil）
    let localFileURL: URL?

    init(
        id: String,
        name: String,
        category: SoundCategory,
        fileName: String,
        fileExtension: String = "m4a",
        defaultVolume: Float = 0.5,
        isLoopable: Bool = true,
        localFileURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.defaultVolume = defaultVolume
        self.isLoopable = isLoopable
        self.localFileURL = localFileURL
    }
}
