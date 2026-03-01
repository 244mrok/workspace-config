import Testing
import Foundation
@testable import HeroAcademia

@Suite("BadgeService Tests")
struct BadgeServiceTests {

    @Test("Awards streak7 badge at 7-day streak")
    func streak7Badge() {
        let newBadges = BadgeService.checkNewBadges(
            streak: 7, totalMeasurements: 10, goal: nil, goalProgress: nil, existing: []
        )
        #expect(newBadges.contains { $0.type == .streak7 })
    }

    @Test("Awards multiple streak badges when streak is high")
    func multipleStreakBadges() {
        let newBadges = BadgeService.checkNewBadges(
            streak: 30, totalMeasurements: 30, goal: nil, goalProgress: nil, existing: []
        )
        let types = Set(newBadges.map(\.type))
        #expect(types.contains(.streak7))
        #expect(types.contains(.streak14))
        #expect(types.contains(.streak30))
        #expect(!types.contains(.streak60))
    }

    @Test("Does not duplicate existing badges")
    func noDuplicates() {
        let existing = [Badge(type: .streak7)]
        let newBadges = BadgeService.checkNewBadges(
            streak: 14, totalMeasurements: 14, goal: nil, goalProgress: nil, existing: existing
        )
        #expect(!newBadges.contains { $0.type == .streak7 })
        #expect(newBadges.contains { $0.type == .streak14 })
    }

    @Test("Awards firstMeasurement badge")
    func firstMeasurement() {
        let newBadges = BadgeService.checkNewBadges(
            streak: 1, totalMeasurements: 1, goal: nil, goalProgress: nil, existing: []
        )
        #expect(newBadges.contains { $0.type == .firstMeasurement })
    }

    @Test("Awards measurement count badges")
    func measurementCountBadges() {
        let newBadges = BadgeService.checkNewBadges(
            streak: 1, totalMeasurements: 100, goal: nil, goalProgress: nil, existing: []
        )
        let types = Set(newBadges.map(\.type))
        #expect(types.contains(.firstMeasurement))
        #expect(types.contains(.measurements50))
        #expect(types.contains(.measurements100))
    }

    @Test("Awards goal progress badges")
    func goalProgressBadges() {
        let goal = Goal(
            id: "test-goal",
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: Date().addingTimeInterval(86400 * 90)
        )
        let newBadges = BadgeService.checkNewBadges(
            streak: 1, totalMeasurements: 10, goal: goal, goalProgress: 55.0, existing: []
        )
        let types = Set(newBadges.map(\.type))
        #expect(types.contains(.goalProgress25))
        #expect(types.contains(.goalProgress50))
        #expect(!types.contains(.goalProgress75))
    }

    @Test("Goal badges include goalId")
    func goalBadgesHaveGoalId() {
        let goal = Goal(
            id: "test-goal",
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: Date().addingTimeInterval(86400 * 90)
        )
        let newBadges = BadgeService.checkNewBadges(
            streak: 0, totalMeasurements: 0, goal: goal, goalProgress: 30.0, existing: []
        )
        let goalBadge = newBadges.first { $0.type == .goalProgress25 }
        #expect(goalBadge?.goalId == "test-goal")
    }

    @Test("No goal returns no goal badges")
    func noGoalNoGoalBadges() {
        let newBadges = BadgeService.checkNewBadges(
            streak: 1, totalMeasurements: 1, goal: nil, goalProgress: nil, existing: []
        )
        let goalBadges = newBadges.filter {
            [.goalProgress25, .goalProgress50, .goalProgress75, .goalProgress100].contains($0.type)
        }
        #expect(goalBadges.isEmpty)
    }

    @Test("Returns empty array when all badges already earned")
    func allBadgesAlreadyEarned() {
        let existing = BadgeType.allCases.map { Badge(type: $0) }
        let newBadges = BadgeService.checkNewBadges(
            streak: 365, totalMeasurements: 100,
            goal: Goal(type: .weight, targetValue: 65, startValue: 75, deadline: Date()),
            goalProgress: 100,
            existing: existing
        )
        #expect(newBadges.isEmpty)
    }
}
