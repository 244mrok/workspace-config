import Foundation
import HealthKit

// MARK: - Protocol

protocol HealthKitServiceProtocol {
    var isAvailable: Bool { get }
    var isAuthorized: Bool { get }
    func requestAuthorization() async throws
    func fetchLatestWeight() async throws -> Double?
    func fetchLatestBodyFat() async throws -> Double?
    func fetchWeightHistory(days: Int) async throws -> [(date: Date, value: Double)]
    func saveWeight(_ weightKg: Double, date: Date) async throws
    func saveBodyFat(_ percentage: Double, date: Date) async throws
}

// MARK: - Implementation

final class HealthKitService: HealthKitServiceProtocol {
    private let healthStore: HKHealthStore?

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private(set) var isAuthorized = false

    init() {
        healthStore = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    }

    func requestAuthorization() async throws {
        guard let healthStore else { return }

        let readTypes: Set<HKSampleType> = [
            HKQuantityType(.bodyMass),
            HKQuantityType(.bodyFatPercentage),
            HKQuantityType(.bodyMassIndex),
        ]

        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.bodyMass),
            HKQuantityType(.bodyFatPercentage),
        ]

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    func fetchLatestWeight() async throws -> Double? {
        try await fetchLatestSample(type: .bodyMass, unit: .gramUnit(with: .kilo))
    }

    func fetchLatestBodyFat() async throws -> Double? {
        guard let value = try await fetchLatestSample(type: .bodyFatPercentage, unit: .percent()) else {
            return nil
        }
        return value * 100 // Convert 0.xx → xx%
    }

    func fetchWeightHistory(days: Int) async throws -> [(date: Date, value: Double)] {
        guard let healthStore else { return [] }

        let quantityType = HKQuantityType(.bodyMass)
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())
        let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .forward)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: predicate)],
            sortDescriptors: [sortDescriptor]
        )

        let samples = try await descriptor.result(for: healthStore)
        return samples.map { sample in
            (date: sample.startDate, value: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
        }
    }

    func saveWeight(_ weightKg: Double, date: Date) async throws {
        guard let healthStore else { return }
        let type = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await healthStore.save(sample)
    }

    func saveBodyFat(_ percentage: Double, date: Date) async throws {
        guard let healthStore else { return }
        let type = HKQuantityType(.bodyFatPercentage)
        let quantity = HKQuantity(unit: .percent(), doubleValue: percentage / 100.0)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await healthStore.save(sample)
    }

    // MARK: - Private

    private func fetchLatestSample(
        type identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async throws -> Double? {
        guard let healthStore else { return nil }

        let quantityType = HKQuantityType(identifier)
        let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .reverse)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType)],
            sortDescriptors: [sortDescriptor],
            limit: 1
        )

        let samples = try await descriptor.result(for: healthStore)
        return samples.first?.quantity.doubleValue(for: unit)
    }
}
