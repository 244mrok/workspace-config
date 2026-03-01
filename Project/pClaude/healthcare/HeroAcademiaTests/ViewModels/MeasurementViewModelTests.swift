import Testing
import Foundation
@testable import HeroAcademia

@Suite("MeasurementViewModel Tests")
@MainActor
struct MeasurementViewModelTests {

    @Test("Initial state")
    func initialState() {
        let service = MockFirebaseService()
        let viewModel = MeasurementViewModel(firebaseService: service)

        #expect(viewModel.measurements.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.inputWeight == "")
        #expect(viewModel.inputBodyFat == "")
    }

    @Test("Load measurements")
    func loadMeasurements() async {
        let service = MockFirebaseService()
        service.measurements = [
            BodyMeasurement(weight: 70.5),
            BodyMeasurement(weight: 71.0)
        ]

        let viewModel = MeasurementViewModel(firebaseService: service)
        await viewModel.loadMeasurements()

        #expect(viewModel.measurements.count == 2)
        #expect(!viewModel.isLoading)
    }

    @Test("Add measurement with valid input")
    func addMeasurementValid() async {
        let service = MockFirebaseService()
        let viewModel = MeasurementViewModel(firebaseService: service)

        viewModel.inputWeight = "70.5"
        viewModel.inputBodyFat = "20.0"
        await viewModel.addMeasurement()

        #expect(service.measurements.count == 1)
        #expect(viewModel.inputWeight == "")  // Form reset
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Add measurement with empty input shows error")
    func addMeasurementEmpty() async {
        let service = MockFirebaseService()
        let viewModel = MeasurementViewModel(firebaseService: service)

        viewModel.inputWeight = ""
        viewModel.inputBodyFat = ""
        await viewModel.addMeasurement()

        #expect(service.measurements.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Latest weight returns first measurement")
    func latestWeight() {
        let service = MockFirebaseService()
        let viewModel = MeasurementViewModel(firebaseService: service)
        viewModel.measurements = [
            BodyMeasurement(weight: 70.5),
            BodyMeasurement(weight: 71.0)
        ]

        #expect(viewModel.latestWeight == 70.5)
    }

    @Test("latestWeight finds first non-nil weight independently")
    func latestWeightIndependent() {
        let service = MockFirebaseService()
        let viewModel = MeasurementViewModel(firebaseService: service)
        viewModel.measurements = [
            TestFixtures.measurement(id: "m1", weight: nil, bodyFatPercentage: 19.0),
            TestFixtures.measurement(id: "m2", weight: 70.5, bodyFatPercentage: 20.0)
        ]

        #expect(viewModel.latestWeight == 70.5)
        #expect(viewModel.latestBodyFat == 19.0)
    }

    @Test("latestBodyFat finds first non-nil bodyFat independently")
    func latestBodyFatIndependent() {
        let service = MockFirebaseService()
        let viewModel = MeasurementViewModel(firebaseService: service)
        viewModel.measurements = [
            TestFixtures.measurement(id: "m1", weight: 71.0, bodyFatPercentage: nil),
            TestFixtures.measurement(id: "m2", weight: 70.0, bodyFatPercentage: 20.0)
        ]

        #expect(viewModel.latestWeight == 71.0)
        #expect(viewModel.latestBodyFat == 20.0)
    }

    // MARK: - Calculated BMI

    @Test("calculatedBMI returns value when weight and profile loaded")
    func calculatedBMI() {
        let service = MockFirebaseService()
        let viewModel = MeasurementViewModel(firebaseService: service)
        viewModel.userProfile = TestFixtures.userProfile(height: 170)
        viewModel.inputWeight = "70.0"

        let bmi = viewModel.calculatedBMI
        #expect(bmi != nil)
        #expect(abs(bmi! - 24.22) < 0.1)
    }

    @Test("calculatedBMI nil when no weight input")
    func calculatedBMINilNoWeight() {
        let service = MockFirebaseService()
        let viewModel = MeasurementViewModel(firebaseService: service)
        viewModel.userProfile = TestFixtures.userProfile(height: 170)
        viewModel.inputWeight = ""

        #expect(viewModel.calculatedBMI == nil)
    }

    @Test("calculatedBMI nil when no height in profile")
    func calculatedBMINilNoHeight() {
        let service = MockFirebaseService()
        let viewModel = MeasurementViewModel(firebaseService: service)
        viewModel.userProfile = TestFixtures.userProfile(height: nil)
        viewModel.inputWeight = "70.0"

        #expect(viewModel.calculatedBMI == nil)
    }

    @Test("Reset form clears all fields")
    func resetForm() {
        let service = MockFirebaseService()
        let viewModel = MeasurementViewModel(firebaseService: service)

        viewModel.inputWeight = "70.5"
        viewModel.inputBodyFat = "20.0"
        viewModel.errorMessage = "Some error"

        viewModel.resetForm()

        #expect(viewModel.inputWeight == "")
        #expect(viewModel.inputBodyFat == "")
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Load measurements error handling")
    func loadMeasurementsError() async {
        let service = MockFirebaseService()
        service.shouldThrowError = true

        let viewModel = MeasurementViewModel(firebaseService: service)
        await viewModel.loadMeasurements()

        #expect(viewModel.measurements.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }
}
