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
    func fetchBodyFatHistory(days: Int) async throws -> [(date: Date, value: Double)]
    func fetchStepCounts(days: Int) async throws -> [(date: Date, value: Double)]
    func fetchSleepAnalysis(days: Int) async throws -> [(date: Date, value: Double)]
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
            HKQuantityType(.stepCount),
            HKCategoryType(.sleepAnalysis),
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

    func fetchBodyFatHistory(days: Int) async throws -> [(date: Date, value: Double)] {
        guard let healthStore else { return [] }

        let quantityType = HKQuantityType(.bodyFatPercentage)
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())
        let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .forward)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: predicate)],
            sortDescriptors: [sortDescriptor]
        )

        let samples = try await descriptor.result(for: healthStore)
        return samples.map { sample in
            (date: sample.startDate, value: sample.quantity.doubleValue(for: .percent()) * 100)
        }
    }

    func fetchStepCounts(days: Int) async throws -> [(date: Date, value: Double)] {
        guard let healthStore else { return [] }

        let quantityType = HKQuantityType(.stepCount)
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!

        let interval = DateComponents(day: 1)
        let anchorDate = calendar.startOfDay(for: startDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate),
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )

        return try await withCheckedThrowingContinuation { continuation in
            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var data: [(date: Date, value: Double)] = []
                results?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        data.append((date: statistics.startDate, value: sum.doubleValue(for: .count())))
                    }
                }
                continuation.resume(returning: data)
            }
            healthStore.execute(query)
        }
    }

    func fetchSleepAnalysis(days: Int) async throws -> [(date: Date, value: Double)] {
        guard let healthStore else { return [] }

        let categoryType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sortDescriptor = SortDescriptor(\HKCategorySample.startDate, order: .forward)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: categoryType, predicate: predicate)],
            sortDescriptors: [sortDescriptor]
        )

        let samples = try await descriptor.result(for: healthStore)

        // Aggregate sleep hours by day
        var dailySleep: [Date: Double] = [:]
        for sample in samples {
            // Only count asleep categories (not inBed)
            let value = sample.value
            guard value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
               || value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
               || value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
               || value == HKCategoryValueSleepAnalysis.asleepREM.rawValue else { continue }

            let day = calendar.startOfDay(for: sample.startDate)
            let hours = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0
            dailySleep[day, default: 0] += hours
        }

        return dailySleep
            .map { (date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
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
