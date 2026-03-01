import Foundation

/// Stateless utility for goal-related calculations.
struct GoalEngine {

    /// BMI = weight(kg) / (height(m))²
    static func bmi(weightKg: Double, heightCm: Double) -> Double {
        guard heightCm > 0 else { return 0 }
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    /// Consecutive measurement days counting backward from today.
    static func streak(from measurements: [BodyMeasurement]) -> Int {
        guard !measurements.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Unique measurement dates (start-of-day), sorted descending
        let uniqueDays = Set(measurements.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >)

        var streakCount = 0
        for i in 0..<uniqueDays.count {
            let expectedDate = calendar.date(byAdding: .day, value: -i, to: today)!
            if uniqueDays[i] == expectedDate {
                streakCount += 1
            } else {
                break
            }
        }
        return streakCount
    }

    /// Linear-trend projected completion date for the goal.
    /// Returns nil if trend goes the wrong direction or insufficient data.
    static func projectedCompletionDate(
        goal: Goal,
        recentMeasurements: [BodyMeasurement]
    ) -> Date? {
        // Need at least 2 measurements to compute a trend
        let values: [(date: Date, value: Double)]
        switch goal.type {
        case .weight:
            values = recentMeasurements
                .compactMap { m in m.weight.map { (m.date, $0) } }
        case .bodyFat:
            values = recentMeasurements
                .compactMap { m in m.bodyFatPercentage.map { (m.date, $0) } }
        }

        guard values.count >= 2 else { return nil }

        let sorted = values.sorted { $0.date < $1.date }
        let first = sorted.first!
        let last = sorted.last!

        let daysBetween = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 0
        guard daysBetween > 0 else { return nil }

        let dailyChange = (last.value - first.value) / Double(daysBetween)
        guard dailyChange != 0 else { return nil }

        // Check trend is heading toward the target
        let remaining = goal.targetValue - last.value
        let daysToTarget = remaining / dailyChange
        guard daysToTarget > 0 else { return nil }

        return Calendar.current.date(byAdding: .day, value: Int(ceil(daysToTarget)), to: last.date)
    }

    /// Detect when goal progress crosses a milestone threshold (25/50/75/100%).
    /// Returns the milestone percentage if a threshold was just crossed, nil otherwise.
    static func milestoneReached(goal: Goal, currentValue: Double, previousValue: Double) -> Int? {
        let currentProgress = goal.progressPercentage(currentValue: currentValue)
        let previousProgress = goal.progressPercentage(currentValue: previousValue)

        let milestones = [25, 50, 75, 100]
        for milestone in milestones {
            let threshold = Double(milestone)
            if previousProgress < threshold && currentProgress >= threshold {
                return milestone
            }
        }
        return nil
    }

    /// Required daily pace from current value to reach the goal by deadline.
    static func requiredDailyPace(goal: Goal, currentValue: Double) -> Double {
        let remaining = goal.targetValue - currentValue
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: goal.deadline).day ?? 0
        guard daysLeft > 0 else { return remaining }
        return remaining / Double(daysLeft)
    }
}
