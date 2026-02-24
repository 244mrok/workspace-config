import Testing
import Foundation
import FirebaseFirestore
@testable import HeroAcademia

@Suite("Goal Tests")
struct GoalTests {

    @Test("Goal type display names")
    func goalTypeDisplayNames() {
        #expect(GoalType.weight.displayName == "体重")
        #expect(GoalType.bodyFat.displayName == "体脂肪率")
    }

    @Test("Goal type units")
    func goalTypeUnits() {
        #expect(GoalType.weight.unit == "kg")
        #expect(GoalType.bodyFat.unit == "%")
    }

    @Test("Total change calculation")
    func totalChange() {
        let goal = Goal(
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: Date().addingTimeInterval(86400 * 90)
        )

        #expect(goal.totalChange == -10.0)
    }

    @Test("Daily pace calculation")
    func dailyPace() {
        let startDate = Date()
        let deadline = Calendar.current.date(byAdding: .day, value: 100, to: startDate)!

        let goal = Goal(
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            startDate: startDate,
            deadline: deadline
        )

        #expect(goal.dailyPace < 0)
        #expect(abs(goal.dailyPace - (-0.1)) < 0.01)
    }

    @Test("Progress percentage")
    func progressPercentage() {
        let goal = Goal(
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: Date().addingTimeInterval(86400 * 90)
        )

        let progress = goal.progressPercentage(currentValue: 70.0)
        #expect(progress == 50.0)
    }

    @Test("Progress percentage clamped")
    func progressPercentageClamped() {
        let goal = Goal(
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: Date().addingTimeInterval(86400 * 90)
        )

        let overProgress = goal.progressPercentage(currentValue: 60.0)
        #expect(overProgress == 100.0)
    }

    @Test("Firestore encoding produces correct fields")
    func firestoreEncoding() throws {
        let goal = Goal(
            type: .bodyFat,
            targetValue: 15.0,
            startValue: 25.0,
            startDate: Date(timeIntervalSince1970: 1700000000),
            deadline: Date(timeIntervalSince1970: 1708000000)
        )

        let encoded = try Firestore.Encoder().encode(goal)

        #expect(encoded["type"] as? String == "bodyFat")
        #expect(encoded["targetValue"] as? Double == 15.0)
        #expect(encoded["startValue"] as? Double == 25.0)
        #expect(encoded["isActive"] as? Bool == true)
    }
}
