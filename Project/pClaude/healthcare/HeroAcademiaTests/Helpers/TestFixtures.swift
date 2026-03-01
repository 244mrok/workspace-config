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
        height: Double? = 170.0,
        birthday: Date? = Calendar.current.date(byAdding: .year, value: -30, to: Date()),
        gender: Gender? = .male
    ) -> UserProfile {
        UserProfile(
            email: email,
            displayName: displayName,
            height: height,
            birthday: birthday,
            gender: gender
        )
    }

    static func device(
        id: String? = "test-device-id",
        type: DeviceType = .omron,
        name: String = "テストデバイス",
        lastSyncDate: Date? = nil,
        isConnected: Bool = false
    ) -> HealthDevice {
        HealthDevice(
            id: id,
            type: type,
            name: name,
            lastSyncDate: lastSyncDate,
            isConnected: isConnected
        )
    }

    static func measurementWithComposition(
        id: String? = "test-composition-id",
        date: Date = Date(),
        weight: Double? = 70.0,
        bodyFatPercentage: Double? = 20.0,
        muscleMass: Double? = 30.0,
        visceralFatLevel: Int? = 8,
        metabolicAge: Int? = 28
    ) -> BodyMeasurement {
        BodyMeasurement(
            id: id,
            date: date,
            weight: weight,
            bodyFatPercentage: bodyFatPercentage,
            muscleMass: muscleMass,
            visceralFatLevel: visceralFatLevel,
            metabolicAge: metabolicAge,
            source: .manual
        )
    }

    static func badge(
        id: String? = "test-badge-id",
        type: BadgeType = .streak7,
        earnedDate: Date = Date(),
        goalId: String? = nil
    ) -> Badge {
        Badge(
            id: id,
            type: type,
            earnedDate: earnedDate,
            goalId: goalId
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
