import Testing
import Foundation
@testable import HeroAcademia

@Suite("AnalyticsViewModel Tests")
struct AnalyticsViewModelTests {
    @MainActor
    private func makeViewModel(
        measurements: [BodyMeasurement] = [],
        healthKit: MockHealthKitService? = MockHealthKitService()
    ) -> (AnalyticsViewModel, MockFirebaseService, MockHealthKitService?) {
        let firebase = MockFirebaseService()
        firebase.measurements = measurements
        let vm = AnalyticsViewModel(firebaseService: firebase, healthKitService: healthKit)
        return (vm, firebase, healthKit)
    }

    // MARK: - Weight Trend

    @Test("weightTrendData filters by selected period")
    @MainActor
    func weightTrendFiltering() async {
        let calendar = Calendar.current
        let oldDate = calendar.date(byAdding: .day, value: -60, to: Date())!
        let recentDate = calendar.date(byAdding: .day, value: -3, to: Date())!

        let measurements = [
            TestFixtures.measurement(id: "1", date: oldDate, weight: 75.0),
            TestFixtures.measurement(id: "2", date: recentDate, weight: 72.0),
        ]

        let (vm, _, _) = makeViewModel(measurements: measurements)
        await vm.loadAll()

        vm.selectedPeriod = .week
        #expect(vm.weightTrendData.count == 1)
        #expect(vm.weightTrendData.first?.value == 72.0)
    }

    @Test("weightTrendData sorted ascending by date")
    @MainActor
    func weightTrendSorting() async {
        let calendar = Calendar.current
        let date1 = calendar.date(byAdding: .day, value: -5, to: Date())!
        let date2 = calendar.date(byAdding: .day, value: -2, to: Date())!

        let measurements = [
            TestFixtures.measurement(id: "2", date: date2, weight: 71.0),
            TestFixtures.measurement(id: "1", date: date1, weight: 73.0),
        ]

        let (vm, _, _) = makeViewModel(measurements: measurements)
        await vm.loadAll()
        vm.selectedPeriod = .month

        #expect(vm.weightTrendData.count == 2)
        #expect(vm.weightTrendData.first?.value == 73.0)
        #expect(vm.weightTrendData.last?.value == 71.0)
    }

    @Test("weightTrendData excludes nil weight")
    @MainActor
    func weightTrendExcludesNil() async {
        let measurements = [
            TestFixtures.measurement(id: "1", weight: nil, bodyFatPercentage: 20.0),
            TestFixtures.measurement(id: "2", weight: 70.0),
        ]

        let (vm, _, _) = makeViewModel(measurements: measurements)
        await vm.loadAll()

        #expect(vm.weightTrendData.count == 1)
    }

    // MARK: - Body Fat Trend

    @Test("bodyFatTrendData filters by period")
    @MainActor
    func bodyFatTrendFiltering() async {
        let calendar = Calendar.current
        let oldDate = calendar.date(byAdding: .day, value: -60, to: Date())!
        let recentDate = calendar.date(byAdding: .day, value: -3, to: Date())!

        let measurements = [
            TestFixtures.measurement(id: "1", date: oldDate, bodyFatPercentage: 25.0),
            TestFixtures.measurement(id: "2", date: recentDate, bodyFatPercentage: 22.0),
        ]

        let (vm, _, _) = makeViewModel(measurements: measurements)
        await vm.loadAll()
        vm.selectedPeriod = .week

        #expect(vm.bodyFatTrendData.count == 1)
        #expect(vm.bodyFatTrendData.first?.value == 22.0)
    }

    // MARK: - Correlation

    @Test("sleepWeightCorrelation pairs matching dates")
    @MainActor
    func sleepWeightCorrelation() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let measurements = [
            TestFixtures.measurement(id: "1", date: today, weight: 70.0),
        ]

        let hk = MockHealthKitService()
        hk.sleepData = [(date: today, value: 7.5)]

        let (vm, _, _) = makeViewModel(measurements: measurements, healthKit: hk)
        await vm.loadAll()

        #expect(vm.sleepWeightCorrelation.count == 1)
        #expect(vm.sleepWeightCorrelation.first?.xValue == 7.5)
        #expect(vm.sleepWeightCorrelation.first?.yValue == 70.0)
    }

    @Test("sleepWeightCorrelation empty when no matching dates")
    @MainActor
    func sleepWeightCorrelationEmpty() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let measurements = [
            TestFixtures.measurement(id: "1", date: today, weight: 70.0),
        ]

        let hk = MockHealthKitService()
        hk.sleepData = [(date: yesterday, value: 7.5)]

        let (vm, _, _) = makeViewModel(measurements: measurements, healthKit: hk)
        await vm.loadAll()

        #expect(vm.sleepWeightCorrelation.isEmpty)
    }

    @Test("stepsBodyFatCorrelation pairs matching dates")
    @MainActor
    func stepsBodyFatCorrelation() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let measurements = [
            TestFixtures.measurement(id: "1", date: today, bodyFatPercentage: 20.0),
        ]

        let hk = MockHealthKitService()
        hk.stepCounts = [(date: today, value: 8000)]

        let (vm, _, _) = makeViewModel(measurements: measurements, healthKit: hk)
        await vm.loadAll()

        #expect(vm.stepsBodyFatCorrelation.count == 1)
        #expect(vm.stepsBodyFatCorrelation.first?.xValue == 8000)
        #expect(vm.stepsBodyFatCorrelation.first?.yValue == 20.0)
    }

    // MARK: - Composition Breakdown

    @Test("compositionBreakdown with muscleMass shows 3 segments")
    @MainActor
    func compositionWithMuscle() async {
        let measurements = [
            TestFixtures.measurementWithComposition(
                weight: 70.0,
                bodyFatPercentage: 20.0,
                muscleMass: 30.0
            ),
        ]

        let (vm, _, _) = makeViewModel(measurements: measurements)
        await vm.loadAll()

        #expect(vm.compositionBreakdown.count == 3)
        #expect(vm.compositionBreakdown[0].label == "筋肉量")
        #expect(vm.compositionBreakdown[0].value == 30.0)
        #expect(vm.compositionBreakdown[1].label == "脂肪量")
        #expect(vm.compositionBreakdown[1].value == 14.0) // 70 * 0.20
    }

    @Test("compositionBreakdown without muscleMass shows 2 segments")
    @MainActor
    func compositionWithoutMuscle() async {
        let measurements = [
            TestFixtures.measurement(weight: 70.0, bodyFatPercentage: 20.0),
        ]

        let (vm, _, _) = makeViewModel(measurements: measurements)
        await vm.loadAll()

        #expect(vm.compositionBreakdown.count == 2)
        #expect(vm.compositionBreakdown[0].label == "除脂肪体重")
        #expect(vm.compositionBreakdown[1].label == "脂肪量")
    }

    @Test("compositionBreakdown empty without weight")
    @MainActor
    func compositionEmptyWithoutWeight() async {
        let measurements = [
            TestFixtures.measurement(weight: nil, bodyFatPercentage: 20.0),
        ]

        let (vm, _, _) = makeViewModel(measurements: measurements)
        await vm.loadAll()

        #expect(vm.compositionBreakdown.isEmpty)
    }

    // MARK: - Heatmap

    @Test("heatmapData groups by day")
    @MainActor
    func heatmapGrouping() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let measurements = [
            TestFixtures.measurement(id: "1", date: today),
            TestFixtures.measurement(id: "2", date: today.addingTimeInterval(3600)),
        ]

        let (vm, _, _) = makeViewModel(measurements: measurements)
        await vm.loadAll()

        let todayEntry = vm.heatmapData.first { calendar.isDate($0.date, inSameDayAs: today) }
        #expect(todayEntry?.count == 2)
    }

    @Test("heatmapData sorted by date")
    @MainActor
    func heatmapSorted() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let measurements = [
            TestFixtures.measurement(id: "1", date: today),
            TestFixtures.measurement(id: "2", date: yesterday),
        ]

        let (vm, _, _) = makeViewModel(measurements: measurements)
        await vm.loadAll()

        #expect(vm.heatmapData.count == 2)
        #expect(vm.heatmapData.first!.date < vm.heatmapData.last!.date)
    }

    // MARK: - Loading

    @Test("loadAll sets isLoading")
    @MainActor
    func loadingState() async {
        let (vm, _, _) = makeViewModel()
        #expect(!vm.isLoading)

        await vm.loadAll()

        #expect(!vm.isLoading)
    }

    @Test("loadAll handles errors")
    @MainActor
    func loadError() async {
        let firebase = MockFirebaseService()
        firebase.shouldThrowError = true
        let vm = AnalyticsViewModel(firebaseService: firebase)

        await vm.loadAll()

        #expect(vm.errorMessage != nil)
    }

    @Test("Period change affects filtering window")
    @MainActor
    func periodChange() async {
        let calendar = Calendar.current
        let date15DaysAgo = calendar.date(byAdding: .day, value: -15, to: Date())!

        let measurements = [
            TestFixtures.measurement(id: "1", date: date15DaysAgo, weight: 73.0),
            TestFixtures.measurement(id: "2", date: Date(), weight: 71.0),
        ]

        let (vm, _, _) = makeViewModel(measurements: measurements)
        await vm.loadAll()

        vm.selectedPeriod = .week
        #expect(vm.weightTrendData.count == 1)

        vm.selectedPeriod = .month
        #expect(vm.weightTrendData.count == 2)
    }
}
