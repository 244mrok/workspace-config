import Testing
import Foundation
@testable import HeroAcademia

@Suite("GoalEngine Tests")
struct GoalEngineTests {

    // MARK: - BMI

    @Test("BMI calculation — normal case")
    func bmiNormal() {
        // 70kg, 170cm → BMI ≈ 24.22
        let result = GoalEngine.bmi(weightKg: 70, heightCm: 170)
        #expect(abs(result - 24.22) < 0.1)
    }

    @Test("BMI calculation — zero height returns 0")
    func bmiZeroHeight() {
        #expect(GoalEngine.bmi(weightKg: 70, heightCm: 0) == 0)
    }

    // MARK: - Streak

    @Test("Streak — consecutive days from today")
    func streakConsecutive() {
        let calendar = Calendar.current
        let today = Date()
        let measurements = (0..<5).map { dayOffset in
            BodyMeasurement(
                date: calendar.date(byAdding: .day, value: -dayOffset, to: today)!,
                weight: 70
            )
        }
        #expect(GoalEngine.streak(from: measurements) == 5)
    }

    @Test("Streak — gap breaks streak")
    func streakWithGap() {
        let calendar = Calendar.current
        let today = Date()
        // Today, yesterday, then skip day before
        let measurements = [
            BodyMeasurement(date: today, weight: 70),
            BodyMeasurement(date: calendar.date(byAdding: .day, value: -1, to: today)!, weight: 70),
            BodyMeasurement(date: calendar.date(byAdding: .day, value: -3, to: today)!, weight: 70),
        ]
        #expect(GoalEngine.streak(from: measurements) == 2)
    }

    @Test("Streak — empty measurements returns 0")
    func streakEmpty() {
        #expect(GoalEngine.streak(from: []) == 0)
    }

    @Test("Streak — no measurement today returns 0")
    func streakNoToday() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let measurements = [BodyMeasurement(date: yesterday, weight: 70)]
        #expect(GoalEngine.streak(from: measurements) == 0)
    }

    // MARK: - Projected Completion Date

    @Test("Projected completion — downward weight trend")
    func projectedCompletion() {
        let calendar = Calendar.current
        let today = Date()
        // Losing 0.1 kg/day over 10 days: 75 → 74
        let measurements = (0..<10).reversed().map { dayOffset in
            BodyMeasurement(
                date: calendar.date(byAdding: .day, value: -dayOffset, to: today)!,
                weight: 75.0 - Double(9 - dayOffset) * 0.1
            )
        }

        let goal = Goal(
            type: .weight,
            targetValue: 70.0,
            startValue: 75.0,
            deadline: calendar.date(byAdding: .day, value: 90, to: today)!
        )

        let projected = GoalEngine.projectedCompletionDate(goal: goal, recentMeasurements: measurements)
        #expect(projected != nil)
    }

    @Test("Projected completion — insufficient data returns nil")
    func projectedCompletionInsufficientData() {
        let goal = Goal(
            type: .weight,
            targetValue: 70.0,
            startValue: 75.0,
            deadline: Date().addingTimeInterval(86400 * 90)
        )
        let measurements = [BodyMeasurement(date: Date(), weight: 74.0)]
        #expect(GoalEngine.projectedCompletionDate(goal: goal, recentMeasurements: measurements) == nil)
    }

    @Test("Projected completion — wrong direction returns nil")
    func projectedCompletionWrongDirection() {
        let calendar = Calendar.current
        let today = Date()
        // Gaining weight when trying to lose
        let measurements = [
            BodyMeasurement(date: calendar.date(byAdding: .day, value: -5, to: today)!, weight: 74.0),
            BodyMeasurement(date: today, weight: 76.0),
        ]
        let goal = Goal(
            type: .weight,
            targetValue: 70.0,
            startValue: 75.0,
            deadline: calendar.date(byAdding: .day, value: 90, to: today)!
        )
        #expect(GoalEngine.projectedCompletionDate(goal: goal, recentMeasurements: measurements) == nil)
    }

    // MARK: - Required Daily Pace

    @Test("Required daily pace calculation")
    func requiredDailyPace() {
        let calendar = Calendar.current
        let deadline = calendar.date(byAdding: .day, value: 50, to: Date())!
        let goal = Goal(
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: deadline
        )

        let pace = GoalEngine.requiredDailyPace(goal: goal, currentValue: 70.0)
        // Need to lose 5kg in 50 days = -0.1 kg/day
        #expect(abs(pace - (-0.1)) < 0.01)
    }

    // MARK: - Milestone Detection

    @Test("Milestone — crossing 50% threshold")
    func milestoneAt50() {
        let goal = Goal(
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: Date().addingTimeInterval(86400 * 90)
        )
        // Progress from 40% (71.0) to 55% (69.5) — crosses 50%
        let milestone = GoalEngine.milestoneReached(goal: goal, currentValue: 69.5, previousValue: 71.0)
        #expect(milestone == 50)
    }

    @Test("Milestone — no threshold crossed returns nil")
    func milestoneNoCross() {
        let goal = Goal(
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: Date().addingTimeInterval(86400 * 90)
        )
        // Both within same bracket (40%-50%)
        let milestone = GoalEngine.milestoneReached(goal: goal, currentValue: 71.5, previousValue: 72.0)
        #expect(milestone == nil)
    }

    @Test("Milestone — crossing 100% threshold")
    func milestoneAt100() {
        let goal = Goal(
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: Date().addingTimeInterval(86400 * 90)
        )
        // Progress from 95% to 100%
        let milestone = GoalEngine.milestoneReached(goal: goal, currentValue: 65.0, previousValue: 65.5)
        #expect(milestone == 100)
    }

    @Test("Required daily pace — past deadline")
    func requiredDailyPacePastDeadline() {
        let calendar = Calendar.current
        let deadline = calendar.date(byAdding: .day, value: -1, to: Date())!
        let goal = Goal(
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: deadline
        )
        // Should return full remaining amount
        let pace = GoalEngine.requiredDailyPace(goal: goal, currentValue: 70.0)
        #expect(abs(pace - (-5.0)) < 0.1)
    }
}
