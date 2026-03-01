import Foundation

struct NotificationSettings: Codable, Equatable {
    var isWeighInReminderEnabled: Bool
    var weighInReminderHour: Int
    var weighInReminderMinute: Int
    var isMilestoneEnabled: Bool
    var isStreakEnabled: Bool
    var isWeeklyReportEnabled: Bool

    init(
        isWeighInReminderEnabled: Bool = true,
        weighInReminderHour: Int = 7,
        weighInReminderMinute: Int = 0,
        isMilestoneEnabled: Bool = true,
        isStreakEnabled: Bool = true,
        isWeeklyReportEnabled: Bool = true
    ) {
        self.isWeighInReminderEnabled = isWeighInReminderEnabled
        self.weighInReminderHour = weighInReminderHour
        self.weighInReminderMinute = weighInReminderMinute
        self.isMilestoneEnabled = isMilestoneEnabled
        self.isStreakEnabled = isStreakEnabled
        self.isWeeklyReportEnabled = isWeeklyReportEnabled
    }
}
