import Foundation
@testable import HeroAcademia

final class MockHealthKitService: HealthKitServiceProtocol {
    var isAvailable: Bool = true
    var isAuthorized: Bool = false
    var shouldThrowError = false

    var latestWeight: Double?
    var latestBodyFat: Double?
    var weightHistory: [(date: Date, value: Double)] = []
    var savedWeights: [(value: Double, date: Date)] = []
    var savedBodyFats: [(value: Double, date: Date)] = []

    func requestAuthorization() async throws {
        if shouldThrowError { throw MockHealthKitError.testError }
        isAuthorized = true
    }

    func fetchLatestWeight() async throws -> Double? {
        if shouldThrowError { throw MockHealthKitError.testError }
        return latestWeight
    }

    func fetchLatestBodyFat() async throws -> Double? {
        if shouldThrowError { throw MockHealthKitError.testError }
        return latestBodyFat
    }

    func fetchWeightHistory(days: Int) async throws -> [(date: Date, value: Double)] {
        if shouldThrowError { throw MockHealthKitError.testError }
        return weightHistory
    }

    func saveWeight(_ weightKg: Double, date: Date) async throws {
        if shouldThrowError { throw MockHealthKitError.testError }
        savedWeights.append((value: weightKg, date: date))
    }

    func saveBodyFat(_ percentage: Double, date: Date) async throws {
        if shouldThrowError { throw MockHealthKitError.testError }
        savedBodyFats.append((value: percentage, date: date))
    }

    enum MockHealthKitError: Error {
        case testError
    }
}
