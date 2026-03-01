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
