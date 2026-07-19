//
//  MixPreset.swift
//  Unhurry
//

import Foundation

/// 混音预设——保存一组音效 ID 及其各自音量，便于一键召回。
struct MixPreset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    /// 音效 ID 列表
    let trackIds: [String]
    /// trackId → 音量 (0...1)
    let volumes: [String: Float]
    let createdAt: Date

    init(id: UUID = UUID(), name: String, trackIds: [String], volumes: [String: Float], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.trackIds = trackIds
        self.volumes = volumes
        self.createdAt = createdAt
    }
}
