//
//  UsageTracker.swift
//  Unhurry
//

import SwiftUI
import Observation

/// 一条播放记录
struct PlayRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval  // 秒
    let trackIds: [String]
}

/// 使用统计追踪器——持久化播放记录，提供周统计和排行。
@MainActor
@Observable
final class UsageTracker {
    static let shared = UsageTracker()

    private static let storageKey = "com.unhurry.playRecords"
    private static let maxRecords = 200

    private(set) var records: [PlayRecord] = []

    /// 当前正在播放的音效（记录中，尚未保存）
    private var currentTrackIds: Set<String> = []
    private var sessionStart: Date?

    private init() {
        loadFromDisk()
    }

    // MARK: - Session Lifecycle

    /// 音效开始播放时调用。
    func trackStarted(_ trackId: String) {
        if currentTrackIds.isEmpty {
            sessionStart = Date()
        }
        currentTrackIds.insert(trackId)
    }

    /// 音效停止时调用。
    func trackStopped(_ trackId: String) {
        currentTrackIds.remove(trackId)
        if currentTrackIds.isEmpty {
            finishSession()
        }
    }

    /// 所有音效停止时调用（含定时器触发）。
    func allStopped() {
        guard !currentTrackIds.isEmpty else { return }
        finishSession()
    }

    private func finishSession() {
        guard let start = sessionStart, !currentTrackIds.isEmpty else {
            currentTrackIds.removeAll()
            sessionStart = nil
            return
        }
        let duration = Date().timeIntervalSince(start)
        // 忽略过短的播放（< 5 秒，可能只是试听）
        guard duration >= 5 else {
            currentTrackIds.removeAll()
            sessionStart = nil
            return
        }

        let record = PlayRecord(
            id: UUID(),
            date: start,
            duration: duration,
            trackIds: Array(currentTrackIds)
        )
        records.append(record)
        trimIfNeeded()
        persistToDisk()
        currentTrackIds.removeAll()
        sessionStart = nil

        // 同步到 Apple Health（≥ 1 分钟才记录）
        if duration >= 60 {
            HealthService.saveMindfulSession(start: start, duration: duration)
        }
    }

    // MARK: - Stats

    /// 本周入睡次数（每日一段播放计为一次）
    var weeklySessionCount: Int {
        let calendar = Calendar.current
        let weekStart = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let dailySessions = Dictionary(grouping: records.filter { $0.date >= weekStart }) {
            calendar.startOfDay(for: $0.date)
        }
        return dailySessions.count
    }

    /// 累计收听总时长（格式化）
    var totalDurationFormatted: String {
        let total = records.reduce(0) { $0 + $1.duration }
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        if hours > 0 {
            return "\(hours) 小时 \(minutes) 分钟"
        }
        return "\(minutes) 分钟"
    }

    /// 最爱音效排行（播放次数最多的 Top 5）
    func topTracks(names: (String) -> String) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for record in records {
            for trackId in record.trackIds {
                counts[trackId, default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (names($0.key), $0.value) }
    }

    /// 本周总收听时长（秒）
    var weeklyDuration: TimeInterval {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return records.filter { $0.date >= weekStart }.reduce(0) { $0 + $1.duration }
    }

    var weeklyDurationFormatted: String {
        let total = weeklyDuration
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        if hours > 0 {
            return "\(hours) 小时 \(minutes) 分钟"
        }
        return "\(minutes) 分钟"
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let loaded = try? JSONDecoder().decode([PlayRecord].self, from: data)
        else { return }
        records = loaded
    }

    private func persistToDisk() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func trimIfNeeded() {
        if records.count > Self.maxRecords {
            records = Array(records.suffix(Self.maxRecords))
        }
    }
}
