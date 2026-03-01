import Testing
import Foundation
@testable import HeroAcademia

// MARK: - Mock Firebase Service

final class MockFirebaseService: FirebaseServiceProtocol {
    var currentUserId: String?
    var isAuthenticated: Bool { currentUserId != nil }

    var measurements: [BodyMeasurement] = []
    var userProfile: UserProfile?
    var goals: [Goal] = []

    var signUpCalled = false
    var signInCalled = false
    var signOutCalled = false
    var shouldThrowError = false

    func signUp(email: String, password: String) async throws {
        signUpCalled = true
        if shouldThrowError { throw MockError.testError }
        currentUserId = "mock-user-id"
    }

    func signIn(email: String, password: String) async throws {
        signInCalled = true
        if shouldThrowError { throw MockError.testError }
        currentUserId = "mock-user-id"
    }

    func signOut() throws {
        signOutCalled = true
        if shouldThrowError { throw MockError.testError }
        currentUserId = nil
    }

    func addMeasurement(_ measurement: BodyMeasurement) async throws {
        if shouldThrowError { throw MockError.testError }
        var newMeasurement = measurement
        measurements.append(newMeasurement)
    }

    func fetchMeasurements(limit: Int) async throws -> [BodyMeasurement] {
        if shouldThrowError { throw MockError.testError }
        return Array(measurements.prefix(limit))
    }

    func updateMeasurement(_ measurement: BodyMeasurement) async throws {
        if shouldThrowError { throw MockError.testError }
        if let index = measurements.firstIndex(where: { $0.id == measurement.id }) {
            measurements[index] = measurement
        }
    }

    func deleteMeasurement(id: String) async throws {
        if shouldThrowError { throw MockError.testError }
        measurements.removeAll { $0.id == id }
    }

    func createUserProfile(_ profile: UserProfile) async throws {
        if shouldThrowError { throw MockError.testError }
        userProfile = profile
    }

    func fetchUserProfile() async throws -> UserProfile? {
        if shouldThrowError { throw MockError.testError }
        return userProfile
    }

    func addGoal(_ goal: Goal) async throws {
        if shouldThrowError { throw MockError.testError }
        goals.append(goal)
    }

    func fetchActiveGoals() async throws -> [Goal] {
        if shouldThrowError { throw MockError.testError }
        return goals.filter { $0.isActive }
    }

    func updateGoal(_ goal: Goal) async throws {
        if shouldThrowError { throw MockError.testError }
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        }
    }

    func deactivateGoal(id: String) async throws {
        if shouldThrowError { throw MockError.testError }
        if let index = goals.firstIndex(where: { $0.id == id }) {
            goals[index].isActive = false
        }
    }

    enum MockError: Error {
        case testError
    }
}

@Suite("FirebaseService Mock Tests")
struct FirebaseServiceTests {

    @Test("Sign up sets user ID")
    func signUp() async throws {
        let service = MockFirebaseService()

        try await service.signUp(email: "test@test.com", password: "password123")

        #expect(service.signUpCalled)
        #expect(service.isAuthenticated)
        #expect(service.currentUserId == "mock-user-id")
    }

    @Test("Sign in sets user ID")
    func signIn() async throws {
        let service = MockFirebaseService()

        try await service.signIn(email: "test@test.com", password: "password123")

        #expect(service.signInCalled)
        #expect(service.isAuthenticated)
    }

    @Test("Sign out clears user ID")
    func signOut() async throws {
        let service = MockFirebaseService()
        service.currentUserId = "mock-user-id"

        try service.signOut()

        #expect(service.signOutCalled)
        #expect(!service.isAuthenticated)
    }

    @Test("Add and fetch measurements")
    func addAndFetchMeasurements() async throws {
        let service = MockFirebaseService()

        let measurement = BodyMeasurement(weight: 70.5, bodyFatPercentage: 20.0)
        try await service.addMeasurement(measurement)

        let fetched = try await service.fetchMeasurements(limit: 10)
        #expect(fetched.count == 1)
        #expect(fetched[0].weight == 70.5)
    }

    @Test("Add and fetch goals")
    func addAndFetchGoals() async throws {
        let service = MockFirebaseService()

        let goal = Goal(
            type: .weight,
            targetValue: 65.0,
            startValue: 75.0,
            deadline: Date().addingTimeInterval(86400 * 90)
        )
        try await service.addGoal(goal)

        let fetched = try await service.fetchActiveGoals()
        #expect(fetched.count == 1)
        #expect(fetched[0].type == .weight)
    }

    @Test("Error handling")
    func errorHandling() async {
        let service = MockFirebaseService()
        service.shouldThrowError = true

        do {
            try await service.signIn(email: "test@test.com", password: "password")
            Issue.record("Should have thrown")
        } catch {
            // Expected
        }
    }
}
