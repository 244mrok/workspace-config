import Foundation

@MainActor
@Observable
final class DashboardViewModel {
    var measurements: [BodyMeasurement] = []
    var activeGoal: Goal?
    var userProfile: UserProfile?
    var isLoading = false
    var errorMessage: String?

    private let firebaseService: FirebaseServiceProtocol

    init(firebaseService: FirebaseServiceProtocol) {
        self.firebaseService = firebaseService
    }

    // MARK: - Computed

    var latestMeasurement: BodyMeasurement? {
        measurements.first
    }

    var latestWeight: Double? {
        latestMeasurement?.weight
    }

    var latestBodyFat: Double? {
        latestMeasurement?.bodyFatPercentage
    }

    var calculatedBMI: Double? {
        guard let weight = latestWeight,
              let height = userProfile?.height,
              height > 0 else { return nil }
        return GoalEngine.bmi(weightKg: weight, heightCm: height)
    }

    var goalProgress: Double? {
        guard let goal = activeGoal else { return nil }
        switch goal.type {
        case .weight:
            guard let w = latestWeight else { return nil }
            return goal.progressPercentage(currentValue: w)
        case .bodyFat:
            guard let bf = latestBodyFat else { return nil }
            return goal.progressPercentage(currentValue: bf)
        }
    }

    var currentGoalValue: Double? {
        guard let goal = activeGoal else { return nil }
        switch goal.type {
        case .weight: return latestWeight
        case .bodyFat: return latestBodyFat
        }
    }

    var projectedDate: Date? {
        guard let goal = activeGoal else { return nil }
        return GoalEngine.projectedCompletionDate(goal: goal, recentMeasurements: measurements)
    }

    var streak: Int {
        GoalEngine.streak(from: measurements)
    }

    // MARK: - Actions

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            async let fetchedMeasurements = firebaseService.fetchMeasurements(limit: 30)
            async let fetchedGoals = firebaseService.fetchActiveGoals()
            async let fetchedProfile = firebaseService.fetchUserProfile()

            measurements = try await fetchedMeasurements
            let goals = try await fetchedGoals
            activeGoal = goals.first
            userProfile = try await fetchedProfile
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
