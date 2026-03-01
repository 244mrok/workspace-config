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
    private let healthKitService: HealthKitServiceProtocol?
    private var listener: ListenerRegistration?

    init(
        firebaseService: FirebaseServiceProtocol,
        healthKitService: HealthKitServiceProtocol? = nil
    ) {
        self.firebaseService = firebaseService
        self.healthKitService = healthKitService
    }

    // MARK: - Computed

    var latestWeight: Double? {
        measurements.first(where: { $0.weight != nil })?.weight
    }

    var latestBodyFat: Double? {
        measurements.first(where: { $0.bodyFatPercentage != nil })?.bodyFatPercentage
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

        // Calculate BMI if weight is available
        var bmi: Double?
        if let weight {
            let profile = try? await firebaseService.fetchUserProfile()
            if let height = profile?.height, height > 0 {
                bmi = GoalEngine.bmi(weightKg: weight, heightCm: height)
            }
        }

        let measurement = BodyMeasurement(
            date: inputDate,
            weight: weight,
            bodyFatPercentage: bodyFat,
            bmi: bmi,
            source: .manual
        )

        do {
            try await firebaseService.addMeasurement(measurement)

            // Write-through to HealthKit
            if let hk = healthKitService, hk.isAuthorized {
                if let weight {
                    try? await hk.saveWeight(weight, date: inputDate)
                }
                if let bodyFat {
                    try? await hk.saveBodyFat(bodyFat, date: inputDate)
                }
            }

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
