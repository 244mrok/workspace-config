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
        #expect(vm.activeGoals.count == 1)
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
        #expect(vm.activeGoals.isEmpty)
        #expect(vm.activeGoal == nil)
        #expect(vm.calculatedBMI == nil)
        #expect(vm.streak == 0)
    }

    @Test("Weight-only record preserves previous body fat")
    @MainActor
    func weightOnlyPreservesBodyFat() async {
        let service = makeService()
        service.measurements = [
            TestFixtures.measurement(id: "m1", weight: 71.0, bodyFatPercentage: nil),
            TestFixtures.measurement(id: "m2", weight: 70.0, bodyFatPercentage: 20.0)
        ]

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.latestWeight == 71.0)
        #expect(vm.latestBodyFat == 20.0)
    }

    @Test("Body-fat-only record preserves previous weight")
    @MainActor
    func bodyFatOnlyPreservesWeight() async {
        let service = makeService()
        service.measurements = [
            TestFixtures.measurement(id: "m1", weight: nil, bodyFatPercentage: 19.0),
            TestFixtures.measurement(id: "m2", weight: 70.0, bodyFatPercentage: 20.0)
        ]

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.latestWeight == 70.0)
        #expect(vm.latestBodyFat == 19.0)
    }

    @Test("All-nil measurements return nil for both")
    @MainActor
    func allNilMeasurements() async {
        let service = makeService()
        service.measurements = [
            TestFixtures.measurement(id: "m1", weight: nil, bodyFatPercentage: nil)
        ]

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.latestWeight == nil)
        #expect(vm.latestBodyFat == nil)
    }

    // MARK: - TDEE

    @Test("TDEE calculated when all profile fields present")
    @MainActor
    func tdeeCalculated() async {
        let service = makeService()
        service.measurements = [TestFixtures.measurement(weight: 70.0, bodyFatPercentage: 20.0)]
        service.userProfile = TestFixtures.userProfile(height: 170, birthday: Calendar.current.date(byAdding: .year, value: -30, to: Date()), gender: .male)

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.estimatedTDEE != nil)
        // Katch-McArdle: LBM=56, BMR=370+21.6×56=1579.6, TDEE=1579.6×1.375≈2172
        #expect(abs(vm.estimatedTDEE! - 2172.0) < 5.0)
    }

    @Test("TDEE nil when birthday missing")
    @MainActor
    func tdeeNilWithoutBirthday() async {
        let service = makeService()
        service.measurements = [TestFixtures.measurement(weight: 70.0)]
        service.userProfile = TestFixtures.userProfile(height: 170, birthday: nil, gender: .male)

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.estimatedTDEE == nil)
    }

    @Test("TDEE nil when gender missing")
    @MainActor
    func tdeeNilWithoutGender() async {
        let service = makeService()
        service.measurements = [TestFixtures.measurement(weight: 70.0)]
        service.userProfile = TestFixtures.userProfile(height: 170, gender: nil)

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.estimatedTDEE == nil)
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

    // MARK: - Multiple Goals

    @Test("Both weight and body fat goals active simultaneously")
    @MainActor
    func multipleActiveGoals() async {
        let service = makeService()
        service.goals = [
            TestFixtures.goal(id: "g-weight", type: .weight, targetValue: 65.0, startValue: 75.0),
            TestFixtures.goal(id: "g-fat", type: .bodyFat, targetValue: 15.0, startValue: 25.0)
        ]
        service.measurements = [
            TestFixtures.measurement(weight: 70.0, bodyFatPercentage: 20.0)
        ]

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.activeGoals.count == 2)
        #expect(vm.weightGoal?.id == "g-weight")
        #expect(vm.bodyFatGoal?.id == "g-fat")
    }

    @Test("weightGoal returns only weight type, bodyFatGoal returns only body fat type")
    @MainActor
    func goalTypeHelpers() async {
        let service = makeService()
        service.goals = [
            TestFixtures.goal(id: "g-fat", type: .bodyFat, targetValue: 15.0, startValue: 25.0),
            TestFixtures.goal(id: "g-weight", type: .weight, targetValue: 65.0, startValue: 75.0)
        ]
        service.measurements = [TestFixtures.measurement(weight: 70.0, bodyFatPercentage: 20.0)]

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        #expect(vm.weightGoal?.type == .weight)
        #expect(vm.bodyFatGoal?.type == .bodyFat)
        // activeGoal is backward compat — returns first in array
        #expect(vm.activeGoal?.id == "g-fat")
    }

    @Test("Per-goal progress calculation")
    @MainActor
    func perGoalProgress() async {
        let service = makeService()
        // Weight: 75 → 65 (10kg loss), current 70 → 50%
        // Body fat: 25 → 15 (10% loss), current 20 → 50%
        service.goals = [
            TestFixtures.goal(id: "g-weight", type: .weight, targetValue: 65.0, startValue: 75.0),
            TestFixtures.goal(id: "g-fat", type: .bodyFat, targetValue: 15.0, startValue: 25.0)
        ]
        service.measurements = [TestFixtures.measurement(weight: 70.0, bodyFatPercentage: 20.0)]

        let vm = DashboardViewModel(firebaseService: service)
        await vm.loadAll()

        let weightProgress = vm.goalProgress(for: vm.weightGoal!)
        let fatProgress = vm.goalProgress(for: vm.bodyFatGoal!)
        #expect(abs(weightProgress! - 50.0) < 0.1)
        #expect(abs(fatProgress! - 50.0) < 0.1)
    }
}
