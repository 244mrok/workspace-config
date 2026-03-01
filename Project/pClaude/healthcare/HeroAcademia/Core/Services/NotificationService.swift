import Foundation
import UserNotifications

// MARK: - Protocol

protocol NotificationServiceProtocol {
    func requestAuthorization() async throws -> Bool
    func scheduleWeighInReminder(hour: Int, minute: Int) async
    func cancelWeighInReminder() async
    func sendMilestoneNotification(percentage: Int, goalType: GoalType) async
    func sendStreakNotification(days: Int) async
    func scheduleWeeklyReport() async
    func cancelWeeklyReport() async
    func cancelAllNotifications() async
}

// MARK: - Implementation

final class NotificationService: NotificationServiceProtocol {
    private let center = UNUserNotificationCenter.current()

    private enum Identifier {
        static let weighInReminder = "com.heroacademia.weighin"
        static let weeklyReport = "com.heroacademia.weekly"
        static let milestone = "com.heroacademia.milestone"
        static let streak = "com.heroacademia.streak"
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    // MARK: - Weigh-In Reminder

    func scheduleWeighInReminder(hour: Int, minute: Int) async {
        await cancelWeighInReminder()

        let content = UNMutableNotificationContent()
        content.title = "計測リマインダー"
        content.body = "今日の体重を記録しましょう！"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.weighInReminder,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func cancelWeighInReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.weighInReminder])
    }

    // MARK: - Milestone

    func sendMilestoneNotification(percentage: Int, goalType: GoalType) async {
        let content = UNMutableNotificationContent()
        content.title = "マイルストーン達成！"
        content.body = "\(goalType.displayName)目標の\(percentage)%を達成しました！"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(Identifier.milestone).\(percentage)",
            content: content,
            trigger: nil
        )

        try? await center.add(request)
    }

    // MARK: - Streak

    private static let streakMilestones: Set<Int> = [7, 14, 30, 60, 100, 365]

    func sendStreakNotification(days: Int) async {
        guard Self.streakMilestones.contains(days) else { return }

        let content = UNMutableNotificationContent()
        content.title = "連続記録達成！"
        content.body = "\(days)日連続で記録を続けています！素晴らしい！"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(Identifier.streak).\(days)",
            content: content,
            trigger: nil
        )

        try? await center.add(request)
    }

    // MARK: - Weekly Report

    func scheduleWeeklyReport() async {
        await cancelWeeklyReport()

        let content = UNMutableNotificationContent()
        content.title = "週次レポート"
        content.body = "今週の体組成の変化を確認しましょう"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.weeklyReport,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func cancelWeeklyReport() async {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.weeklyReport])
    }

    // MARK: - Cancel All

    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
    }
}
