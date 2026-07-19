//
//  UnhurryWidget.swift
//  UnhurryWidget
//

import WidgetKit
import SwiftUI

// MARK: - Widget

struct UnhurryWidget: Widget {
    let kind = "UnhurryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PresetProvider()) { entry in
            UnhurryWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("闲眠")
        .description("一键启动助眠音效组合")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

// MARK: - Entry View

struct UnhurryWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: PresetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            systemSmallView
        case .systemMedium:
            systemMediumView
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        case .accessoryInline:
            accessoryInlineView
        @unknown default:
            systemSmallView
        }
    }

    // MARK: - System Small

    private var systemSmallView: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.stars.fill")
                .font(.title)
                .foregroundStyle(.orange)
            Text(entry.presets.first?.name ?? "创建组合")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(presetURL(entry.presets.first))
    }

    // MARK: - System Medium

    private var systemMediumView: some View {
        let items = Array(entry.presets.prefix(4))
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(.orange)
                Text("闲眠")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            if items.isEmpty {
                Spacer()
                Text("保存音效组合后\n出现在这里")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                HStack(spacing: 10) {
                    ForEach(items) { preset in
                        Link(destination: presetURL(preset) ?? URL(string: "unhurry://")!) {
                            VStack(spacing: 6) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                Text(preset.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(12)
    }

    // MARK: - Accessory Circular

    private var accessoryCircularView: some View {
        ZStack {
            Circle()
                .fill(.orange.opacity(0.2))
            Image(systemName: entry.presets.first != nil ? "play.fill" : "moon.stars.fill")
                .font(.title3)
        }
        .widgetURL(presetURL(entry.presets.first))
    }

    // MARK: - Accessory Rectangular

    private var accessoryRectangularView: some View {
        HStack(spacing: 4) {
            Image(systemName: "moon.stars.fill")
            Text(entry.presets.first?.name ?? "闲眠")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .widgetURL(presetURL(entry.presets.first))
    }

    // MARK: - Accessory Inline

    private var accessoryInlineView: some View {
        Text(entry.presets.first.map { "🌙 \($0.name)" } ?? "闲眠")
            .widgetURL(presetURL(entry.presets.first))
    }

    // MARK: - URL Helper

    private func presetURL(_ preset: MixPreset?) -> URL? {
        guard let preset = preset else { return nil }
        return URL(string: "unhurry://play?id=\(preset.id.uuidString)")
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    UnhurryWidget()
} timeline: {
    PresetEntry(date: Date(), presets: [
        MixPreset(name: "睡前雨声", trackIds: [], volumes: [:]),
    ])
}
