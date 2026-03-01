import Foundation

@MainActor
@Observable
final class NotificationSettingsViewModel {
    var settings = NotificationSettings()
    var isLoading = false
    var errorMessage: String?
    var isAuthorized = false

    // Computed binding for DatePicker
    var reminderTime: Date {
        get {
            var components = DateComponents()
            components.hour = settings.weighInReminderHour
            components.minute = settings.weighInReminderMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            settings.weighInReminderHour = components.hour ?? 7
            settings.weighInReminderMinute = components.minute ?? 0
        }
    }

    private let firebaseService: FirebaseServiceProtocol
    private let notificationService: NotificationServiceProtocol

    init(
        firebaseService: FirebaseServiceProtocol,
        notificationService: NotificationServiceProtocol = NotificationService()
    ) {
        self.firebaseService = firebaseService
        self.notificationService = notificationService
    }

    func loadSettings() async {
        isLoading = true
        do {
            if let saved = try await firebaseService.fetchNotificationSettings() {
                settings = saved
            }
            isAuthorized = try await notificationService.requestAuthorization()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveSettings() async {
        do {
            try await firebaseService.saveNotificationSettings(settings)
            await applySchedules()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applySchedules() async {
        if settings.isWeighInReminderEnabled {
            await notificationService.scheduleWeighInReminder(
                hour: settings.weighInReminderHour,
                minute: settings.weighInReminderMinute
            )
        } else {
            await notificationService.cancelWeighInReminder()
        }

        if settings.isWeeklyReportEnabled {
            await notificationService.scheduleWeeklyReport()
        } else {
            await notificationService.cancelWeeklyReport()
        }
    }
}
