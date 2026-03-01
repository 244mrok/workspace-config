import Foundation

@MainActor
@Observable
final class WatchViewModel {
    let sessionService: WatchSessionService

    init(sessionService: WatchSessionService) {
        self.sessionService = sessionService
    }

    var weightDisplay: String {
        guard let weight = sessionService.watchData?.latestWeight else { return "--.-" }
        return String(format: "%.1f", weight)
    }

    var bodyFatDisplay: String {
        guard let bf = sessionService.watchData?.latestBodyFat else { return "--.-" }
        return String(format: "%.1f", bf)
    }

    var goalProgress: Double {
        (sessionService.watchData?.goalProgress ?? 0) / 100
    }

    var hasGoal: Bool {
        sessionService.watchData?.goalTargetValue != nil
    }

    var goalTypeDisplay: String {
        switch sessionService.watchData?.goalType {
        case "weight": return "体重"
        case "bodyFat": return "体脂肪率"
        default: return ""
        }
    }

    var goalDaysRemaining: Int {
        sessionService.watchData?.goalDaysRemaining ?? 0
    }

    var streak: Int {
        sessionService.watchData?.streak ?? 0
    }

    var lastUpdated: String {
        guard let date = sessionService.watchData?.lastUpdated else { return "" }
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    var hasData: Bool {
        sessionService.watchData != nil
    }
}
