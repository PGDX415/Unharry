//
//  Provider.swift
//  UnhurryWidget
//

import WidgetKit
import Foundation

// MARK: - Timeline Entry

struct PresetEntry: TimelineEntry {
    let date: Date
    let presets: [MixPreset]
}

// MARK: - Provider

struct PresetProvider: TimelineProvider {

    func placeholder(in context: Context) -> PresetEntry {
        PresetEntry(date: Date(), presets: Self.samplePresets)
    }

    func getSnapshot(in context: Context, completion: @escaping (PresetEntry) -> Void) {
        let presets = loadPresetsFromSharedContainer()
        completion(PresetEntry(date: Date(), presets: presets))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PresetEntry>) -> Void) {
        let presets = loadPresetsFromSharedContainer()
        let entry = PresetEntry(date: Date(), presets: presets)
        // 每小时刷新一次
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }

    // MARK: - Shared Container

    private func loadPresetsFromSharedContainer() -> [MixPreset] {
        guard let defaults = UserDefaults(suiteName: "group.com.gongdexin.paul.Unhurry"),
              let data = defaults.data(forKey: "com.unhurry.mixpresets")
        else { return [] }
        return (try? JSONDecoder().decode([MixPreset].self, from: data)) ?? []
    }

    /// 预览占位数据
    private static var samplePresets: [MixPreset] {
        [
            MixPreset(name: "睡前雨声", trackIds: [], volumes: [:]),
            MixPreset(name: "海边冥想", trackIds: [], volumes: [:]),
            MixPreset(name: "篝火夜读", trackIds: [], volumes: [:]),
            MixPreset(name: "竹林清风", trackIds: [], volumes: [:]),
        ]
    }
}
