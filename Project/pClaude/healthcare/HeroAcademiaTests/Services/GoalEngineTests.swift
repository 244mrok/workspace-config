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

    // MARK: - BMR (Katch-McArdle)

    @Test("BMR with body fat — Katch-McArdle formula")
    func bmrKatchMcArdle() {
        // 70kg, 20% body fat → LBM = 56kg → BMR = 370 + 21.6 × 56 = 1579.6
        let result = GoalEngine.bmr(weightKg: 70, heightCm: 170, age: 30, gender: .male, bodyFatPercentage: 20.0)
        #expect(abs(result - 1579.6) < 0.1)
    }

    // MARK: - BMR (Mifflin-St Jeor)

    @Test("BMR male — Mifflin-St Jeor")
    func bmrMifflinMale() {
        // Male: 10×70 + 6.25×170 - 5×30 + 5 = 700 + 1062.5 - 150 + 5 = 1617.5
        let result = GoalEngine.bmr(weightKg: 70, heightCm: 170, age: 30, gender: .male, bodyFatPercentage: nil)
        #expect(abs(result - 1617.5) < 0.1)
    }

    @Test("BMR female — Mifflin-St Jeor")
    func bmrMifflinFemale() {
        // Female: 10×60 + 6.25×160 - 5×25 - 161 = 600 + 1000 - 125 - 161 = 1314
        let result = GoalEngine.bmr(weightKg: 60, heightCm: 160, age: 25, gender: .female, bodyFatPercentage: nil)
        #expect(abs(result - 1314.0) < 0.1)
    }

    @Test("BMR gender other — average of male/female")
    func bmrGenderOther() {
        let male = GoalEngine.bmr(weightKg: 70, heightCm: 170, age: 30, gender: .male, bodyFatPercentage: nil)
        let female = GoalEngine.bmr(weightKg: 70, heightCm: 170, age: 30, gender: .female, bodyFatPercentage: nil)
        let other = GoalEngine.bmr(weightKg: 70, heightCm: 170, age: 30, gender: .other, bodyFatPercentage: nil)
        #expect(abs(other - (male + female) / 2.0) < 0.1)
    }

    @Test("BMR zero weight returns 0")
    func bmrZeroWeight() {
        #expect(GoalEngine.bmr(weightKg: 0, heightCm: 170, age: 30, gender: .male, bodyFatPercentage: nil) == 0)
    }

    @Test("BMR zero age returns 0")
    func bmrZeroAge() {
        #expect(GoalEngine.bmr(weightKg: 70, heightCm: 170, age: 0, gender: .male, bodyFatPercentage: nil) == 0)
    }

    // MARK: - TDEE

    @Test("TDEE calculation at various activity levels")
    func tdeeCalculation() {
        let bmr = 1600.0
        #expect(abs(GoalEngine.tdee(bmr: bmr, activityLevel: .sedentary) - 1920.0) < 0.1)
        #expect(abs(GoalEngine.tdee(bmr: bmr, activityLevel: .light) - 2200.0) < 0.1)
        #expect(abs(GoalEngine.tdee(bmr: bmr, activityLevel: .moderate) - 2480.0) < 0.1)
        #expect(abs(GoalEngine.tdee(bmr: bmr, activityLevel: .active) - 2760.0) < 0.1)
        #expect(abs(GoalEngine.tdee(bmr: bmr, activityLevel: .veryActive) - 3040.0) < 0.1)
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
