import Foundation
import FirebaseFirestore

@MainActor
@Observable
final class MeasurementViewModel {
    var measurements: [BodyMeasurement] = []
    var isLoading = false
    var errorMessage: String?

    // Input form fields
    var inputWeight: String = ""
    var inputBodyFat: String = ""
    var inputDate: Date = Date()

    private let firebaseService: FirebaseServiceProtocol
    private var listener: ListenerRegistration?

    init(firebaseService: FirebaseServiceProtocol) {
        self.firebaseService = firebaseService
    }

    // MARK: - Computed

    var latestWeight: Double? {
        measurements.first?.weight
    }

    var latestBodyFat: Double? {
        measurements.first?.bodyFatPercentage
    }

    // MARK: - Actions

    func loadMeasurements() async {
        isLoading = true
        errorMessage = nil

        do {
            measurements = try await firebaseService.fetchMeasurements(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func startListening() {
        guard let service = firebaseService as? FirebaseService else { return }
        listener = service.listenToMeasurements { [weak self] measurements in
            self?.measurements = measurements
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addMeasurement() async {
        let weight = Double(inputWeight)
        let bodyFat = Double(inputBodyFat)

        guard weight != nil || bodyFat != nil else {
            errorMessage = "体重または体脂肪率を入力してください"
            return
        }

        var bmi: Double?
        // BMI calculation would need height from user profile
        // For now, leave as nil

        let measurement = BodyMeasurement(
            date: inputDate,
            weight: weight,
            bodyFatPercentage: bodyFat,
            bmi: bmi,
            source: .manual
        )

        do {
            try await firebaseService.addMeasurement(measurement)
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMeasurement(at offsets: IndexSet) async {
        for index in offsets {
            guard let id = measurements[index].id else { continue }
            do {
                try await firebaseService.deleteMeasurement(id: id)
                // Don't remove locally — the Firestore snapshot listener
                // will update measurements automatically.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func resetForm() {
        inputWeight = ""
        inputBodyFat = ""
        inputDate = Date()
        errorMessage = nil
    }
}
