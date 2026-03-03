import Testing
import Foundation
@testable import HeroAcademia

@Suite("GoalViewModel Tests")
struct GoalViewModelTests {

    private func makeService() -> MockFirebaseService {
        let service = MockFirebaseService()
        service.currentUserId = "test-user"
        return service
    }

    @Test("Load goals")
    @MainActor
    func loadGoals() async throws {
        let service = makeService()
        let goal = TestFixtures.goal(id: "g1")
        service.goals = [goal]

        let vm = GoalViewModel(firebaseService: service)
        await vm.loadGoals()

        #expect(vm.goals.count == 1)
        #expect(vm.activeGoal?.id == "g1")
    }

    @Test("Add goal")
    @MainActor
    func addGoal() async throws {
        let service = makeService()
        let vm = GoalViewModel(firebaseService: service)

        vm.inputType = .weight
        vm.inputTargetValue = "65.0"
        vm.inputStartValue = "75.0"
        vm.inputDeadline = Calendar.current.date(byAdding: .day, value: 90, to: Date())!

        await vm.addGoal()

        #expect(vm.errorMessage == nil)
        #expect(service.goals.count == 1)
        #expect(service.goals[0].type == .weight)
        #expect(service.goals[0].targetValue == 65.0)
    }

    @Test("Add goal validation — missing values")
    @MainActor
    func addGoalValidation() async {
        let service = makeService()
        let vm = GoalViewModel(firebaseService: service)

        vm.inputTargetValue = ""
        vm.inputStartValue = ""

        await vm.addGoal()

        #expect(vm.errorMessage != nil)
        #expect(service.goals.isEmpty)
    }

    @Test("Deactivate goal")
    @MainActor
    func deactivateGoal() async {
        let service = makeService()
        let goal = TestFixtures.goal(id: "g1")
        service.goals = [goal]

        let vm = GoalViewModel(firebaseService: service)
        await vm.loadGoals()

        await vm.deactivateGoal(goal)

        #expect(service.goals.first?.isActive == false)
    }

    @Test("Reset form")
    @MainActor
    func resetForm() {
        let service = makeService()
        let vm = GoalViewModel(firebaseService: service)

        vm.inputTargetValue = "65"
        vm.inputStartValue = "75"
        vm.errorMessage = "some error"

        vm.resetForm()

        #expect(vm.inputTargetValue.isEmpty)
        #expect(vm.inputStartValue.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Multiple Goals

    @Test("activeGoalTypes includes all active goal types")
    @MainActor
    func activeGoalTypes() async {
        let service = makeService()
        service.goals = [
            TestFixtures.goal(id: "g1", type: .weight),
            TestFixtures.goal(id: "g2", type: .bodyFat)
        ]

        let vm = GoalViewModel(firebaseService: service)
        await vm.loadGoals()

        #expect(vm.activeGoalTypes.contains(.weight))
        #expect(vm.activeGoalTypes.contains(.bodyFat))
        #expect(vm.activeGoalTypes.count == 2)
    }

    @Test("availableType returns unused type")
    @MainActor
    func availableType() async {
        let service = makeService()
        service.goals = [TestFixtures.goal(id: "g1", type: .weight)]

        let vm = GoalViewModel(firebaseService: service)
        await vm.loadGoals()

        #expect(vm.availableType == .bodyFat)
    }

    @Test("availableType nil when both types used")
    @MainActor
    func availableTypeNilWhenFull() async {
        let service = makeService()
        service.goals = [
            TestFixtures.goal(id: "g1", type: .weight),
            TestFixtures.goal(id: "g2", type: .bodyFat)
        ]

        let vm = GoalViewModel(firebaseService: service)
        await vm.loadGoals()

        #expect(vm.availableType == nil)
    }
}
