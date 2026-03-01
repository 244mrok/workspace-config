import Foundation
@testable import HeroAcademia

/// Factory methods for test data.
enum TestFixtures {

    static func measurement(
        id: String? = "test-measurement-id",
        date: Date = Date(),
        weight: Double? = 70.0,
        bodyFatPercentage: Double? = 20.0,
        bmi: Double? = 24.2,
        source: MeasurementSource = .manual
    ) -> BodyMeasurement {
        BodyMeasurement(
            id: id,
            date: date,
            weight: weight,
            bodyFatPercentage: bodyFatPercentage,
            bmi: bmi,
            source: source
        )
    }

    static func goal(
        id: String? = "test-goal-id",
        type: GoalType = .weight,
        targetValue: Double = 65.0,
        startValue: Double = 75.0,
        startDate: Date = Date(),
        deadline: Date? = nil,
        isActive: Bool = true
    ) -> Goal {
        Goal(
            id: id,
            type: type,
            targetValue: targetValue,
            startValue: startValue,
            startDate: startDate,
            deadline: deadline ?? Calendar.current.date(byAdding: .day, value: 90, to: startDate)!,
            isActive: isActive
        )
    }

    static func userProfile(
        email: String = "test@test.com",
        displayName: String = "テストユーザー",
        height: Double? = 170.0
    ) -> UserProfile {
        UserProfile(
            email: email,
            displayName: displayName,
            height: height
        )
    }

    /// Generate a measurement history with a linear weight trend.
    static func measurementHistory(
        days: Int,
        startWeight: Double,
        dailyChange: Double = -0.05
    ) -> [BodyMeasurement] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<days).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -(days - 1 - dayOffset), to: today)!
            let weight = startWeight + Double(dayOffset) * dailyChange
            return BodyMeasurement(
                id: "history-\(dayOffset)",
                date: date,
                weight: weight,
                bodyFatPercentage: 20.0 + Double(dayOffset) * (dailyChange * 0.5),
                source: .manual
            )
        }
    }
}
