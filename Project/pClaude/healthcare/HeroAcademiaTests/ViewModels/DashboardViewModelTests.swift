import Testing
import Foundation
@testable import HeroAcademia

@Suite("DashboardViewModel Tests")
struct DashboardViewModelTests {

    private func makeService() -> MockFirebaseService {
        let service = MockFirebaseService()
        service.currentUserId = "test-user"
        return service
    }

    @Test("Load all data")
    @MainActor
    func loadAll() async throws {
        let service = makeService()
        service.measurements = [
            TestFixtures.measurement(id: "m1", weight: 72.0, bodyFatPercentage: 18.0)
        ]
        service.goals = [TestFixtures.goal()]
        service.userProfile = TestFixtures.userProfile(height: 170)

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.measurements.count == 1)
        #expect(vm.latestWeight == 72.0)
        #expect(vm.latestBodyFat == 18.0)
        #expect(vm.activeGoal != nil)
        #expect(vm.userProfile != nil)
    }

    @Test("BMI calculation from profile height")
    @MainActor
    func bmiCalculation() async {
        let service = makeService()
        service.measurements = [TestFixtures.measurement(weight: 70.0)]
        service.userProfile = TestFixtures.userProfile(height: 170)

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        let bmi = vm.calculatedBMI
        #expect(bmi != nil)
        #expect(abs(bmi! - 24.22) < 0.1)
    }

    @Test("BMI nil when no height")
    @MainActor
    func bmiNilWithoutHeight() async {
        let service = makeService()
        service.measurements = [TestFixtures.measurement(weight: 70.0)]
        service.userProfile = TestFixtures.userProfile(height: nil)

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.calculatedBMI == nil)
    }

    @Test("Goal progress calculation")
    @MainActor
    func goalProgress() async {
        let service = makeService()
        // Goal: 75 → 65 (10kg loss), current: 70 → 50% progress
        service.goals = [TestFixtures.goal(targetValue: 65.0, startValue: 75.0)]
        service.measurements = [TestFixtures.measurement(weight: 70.0)]

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.goalProgress != nil)
        #expect(abs(vm.goalProgress! - 50.0) < 0.1)
    }

    @Test("Streak calculation")
    @MainActor
    func streakCalculation() async {
        let service = makeService()
        let calendar = Calendar.current
        let today = Date()
        service.measurements = [
            TestFixtures.measurement(id: "m1", date: today, weight: 70),
            TestFixtures.measurement(id: "m2", date: calendar.date(byAdding: .day, value: -1, to: today)!, weight: 70),
            TestFixtures.measurement(id: "m3", date: calendar.date(byAdding: .day, value: -2, to: today)!, weight: 70),
        ]

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.streak == 3)
    }

    @Test("Empty state")
    @MainActor
    func emptyState() async {
        let service = makeService()
        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.measurements.isEmpty)
        #expect(vm.latestWeight == nil)
        #expect(vm.activeGoal == nil)
        #expect(vm.calculatedBMI == nil)
        #expect(vm.streak == 0)
    }

    @Test("Error handling")
    @MainActor
    func errorHandling() async {
        let service = makeService()
        service.shouldThrowError = true

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.errorMessage != nil)
    }
}
