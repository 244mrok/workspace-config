import Foundation

// MARK: - Supporting Types

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case week = "1週間"
    case month = "1ヶ月"
    case threeMonths = "3ヶ月"
    case sixMonths = "6ヶ月"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        }
    }
}

struct CorrelationPoint: Identifiable {
    let id = UUID()
    let xValue: Double
    let yValue: Double
    let date: Date
}

struct CompositionData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: String // Named color for chart
}

struct HeatmapEntry: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

// MARK: - ViewModel

@MainActor
@Observable
final class AnalyticsViewModel {
    var measurements: [BodyMeasurement] = []
    var stepData: [(date: Date, value: Double)] = []
    var sleepData: [(date: Date, value: Double)] = []
    var bodyFatData: [(date: Date, value: Double)] = []
    var selectedPeriod: AnalyticsPeriod = .month
    var isLoading = false
    var errorMessage: String?

    private let firebaseService: FirebaseServiceProtocol
    private let healthKitService: HealthKitServiceProtocol?

    init(firebaseService: FirebaseServiceProtocol, healthKitService: HealthKitServiceProtocol? = nil) {
        self.firebaseService = firebaseService
        self.healthKitService = healthKitService
    }

    // MARK: - Computed Properties

    var weightTrendData: [(date: Date, value: Double)] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date())!
        return measurements
            .compactMap { m in m.weight.map { (m.date, $0) } }
            .filter { $0.0 >= cutoff }
            .sorted { $0.0 < $1.0 }
    }

    var bodyFatTrendData: [(date: Date, value: Double)] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date())!
        return measurements
            .compactMap { m in m.bodyFatPercentage.map { (m.date, $0) } }
            .filter { $0.0 >= cutoff }
            .sorted { $0.0 < $1.0 }
    }

    var sleepWeightCorrelation: [CorrelationPoint] {
        let calendar = Calendar.current
        var result: [CorrelationPoint] = []

        for sleep in sleepData {
            let sleepDay = calendar.startOfDay(for: sleep.date)
            if let measurement = measurements.first(where: {
                calendar.startOfDay(for: $0.date) == sleepDay && $0.weight != nil
            }), let weight = measurement.weight {
                result.append(CorrelationPoint(xValue: sleep.value, yValue: weight, date: sleepDay))
            }
        }
        return result
    }

    var stepsBodyFatCorrelation: [CorrelationPoint] {
        let calendar = Calendar.current
        var result: [CorrelationPoint] = []

        for step in stepData {
            let stepDay = calendar.startOfDay(for: step.date)
            if let measurement = measurements.first(where: {
                calendar.startOfDay(for: $0.date) == stepDay && $0.bodyFatPercentage != nil
            }), let bodyFat = measurement.bodyFatPercentage {
                result.append(CorrelationPoint(xValue: step.value, yValue: bodyFat, date: stepDay))
            }
        }
        return result
    }

    var compositionBreakdown: [CompositionData] {
        guard let latest = measurements.first(where: { $0.weight != nil }),
              let weight = latest.weight else { return [] }

        if let muscleMass = latest.muscleMass, let bodyFat = latest.bodyFatPercentage {
            let fatMass = weight * bodyFat / 100.0
            let other = max(0, weight - muscleMass - fatMass)
            return [
                CompositionData(label: "筋肉量", value: muscleMass, color: "blue"),
                CompositionData(label: "脂肪量", value: fatMass, color: "orange"),
                CompositionData(label: "その他", value: other, color: "gray"),
            ]
        } else if let bodyFat = latest.bodyFatPercentage {
            let fatMass = weight * bodyFat / 100.0
            let leanMass = weight - fatMass
            return [
                CompositionData(label: "除脂肪体重", value: leanMass, color: "blue"),
                CompositionData(label: "脂肪量", value: fatMass, color: "orange"),
            ]
        }

        return []
    }

    var heatmapData: [HeatmapEntry] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]

        for measurement in measurements {
            let day = calendar.startOfDay(for: measurement.date)
            counts[day, default: 0] += 1
        }

        return counts
            .map { HeatmapEntry(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Actions

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            measurements = try await firebaseService.fetchMeasurements(limit: 200)

            if let hk = healthKitService {
                let days = selectedPeriod.days
                async let steps = hk.fetchStepCounts(days: days)
                async let sleep = hk.fetchSleepAnalysis(days: days)
                async let bodyFat = hk.fetchBodyFatHistory(days: days)

                stepData = try await steps
                sleepData = try await sleep
                bodyFatData = try await bodyFat
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
