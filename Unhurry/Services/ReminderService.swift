//
//  ReminderService.swift
//  Unhurry
//

import UserNotifications

/// 就寝提醒服务——每日定时推送本地通知。
@MainActor
enum ReminderService {

    private static let notificationId = "com.unhurry.bedtime"

    // MARK: - Permissions

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Notification auth error: \(error)")
            }
        }
    }

    // MARK: - Scheduling

    /// 根据当前设置更新每日通知。
    static func reschedule() {
        let center = UNUserNotificationCenter.current()

        // 先移除旧通知
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])

        guard Theme.reminderEnabled, let presetId = Theme.reminderPresetId else { return }

        let content = UNMutableNotificationContent()
        content.title = "该睡了 🌙"
        content.body = "点按打开预设，开始宁静入眠"
        content.sound = .default
        content.userInfo = ["presetId": presetId]
        content.interruptionLevel = .timeSensitive

        var components = DateComponents()
        components.hour = Theme.reminderHour == 0 ? 22 : Theme.reminderHour
        components.minute = Theme.reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("⚠️ Reminder schedule error: \(error)")
            }
        }
    }
}
