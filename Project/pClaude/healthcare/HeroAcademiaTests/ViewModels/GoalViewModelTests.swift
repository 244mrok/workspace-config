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
}
