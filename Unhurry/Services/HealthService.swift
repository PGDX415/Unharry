//
//  HealthService.swift
//  Unhurry
//

import HealthKit

/// Apple Health 集成服务——同步正念分钟数。
@MainActor
enum HealthService {

    private static let store = HKHealthStore()

    /// 正念分钟数据类型
    private static let mindfulType: HKCategoryType = {
        guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            fatalError("Mindful Session type not available")
        }
        return type
    }()

    // MARK: - Authorization

    static func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let types: Set<HKSampleType> = [mindfulType]
        do {
            try await store.requestAuthorization(toShare: types, read: [])
        } catch {
            print("⚠️ HealthKit auth error: \(error)")
        }
    }

    // MARK: - Save

    /// 保存一段正念分钟记录。
    /// - Parameters:
    ///   - start: 开始时间
    ///   - duration: 持续秒数
    static func saveMindfulSession(start: Date, duration: TimeInterval) {
        guard Theme.healthSyncEnabled else { return }
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard duration >= 60 else { return }  // HealthKit 要求至少 1 分钟

        let end = start.addingTimeInterval(duration)
        let sample = HKCategorySample(
            type: mindfulType,
            value: 0,
            start: start,
            end: end
        )

        store.save(sample) { success, error in
            if !success {
                print("⚠️ HealthKit save error: \(String(describing: error))")
            }
        }
    }
}
