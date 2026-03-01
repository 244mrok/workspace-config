import Foundation

@MainActor
@Observable
final class DashboardViewModel {
    var measurements: [BodyMeasurement] = []
    var activeGoal: Goal?
    var userProfile: UserProfile?
    var isLoading = false
    var errorMessage: String?
    var earnedBadges: [Badge] = []
    var newlyEarnedBadges: [Badge] = []

    private let firebaseService: FirebaseServiceProtocol
    private let notificationService: NotificationServiceProtocol?

    init(
        firebaseService: FirebaseServiceProtocol,
        notificationService: NotificationServiceProtocol? = nil
    ) {
        self.firebaseService = firebaseService
        self.notificationService = notificationService
    }

    // Exposed for child views that need the service
    var firebaseServiceForBadges: FirebaseServiceProtocol {
        firebaseService
    }

    // MARK: - Computed

    var latestMeasurement: BodyMeasurement? {
        measurements.first
    }

    var latestWeight: Double? {
        measurements.first(where: { $0.weight != nil })?.weight
    }

    var latestBodyFat: Double? {
        measurements.first(where: { $0.bodyFatPercentage != nil })?.bodyFatPercentage
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
            let previousGoalValue = currentGoalValue

            async let fetchedMeasurements = firebaseService.fetchMeasurements(limit: 30)
            async let fetchedGoals = firebaseService.fetchActiveGoals()
            async let fetchedProfile = firebaseService.fetchUserProfile()

            measurements = try await fetchedMeasurements
            let goals = try await fetchedGoals
            activeGoal = goals.first
            userProfile = try await fetchedProfile

            // Check milestone notifications
            await checkMilestone(previousValue: previousGoalValue)

            // Check streak notifications
            await checkStreak()

            // Check badges
            await checkBadges()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func checkMilestone(previousValue: Double?) async {
        guard let goal = activeGoal,
              let current = currentGoalValue,
              let previous = previousValue,
              let notificationService else { return }

        let settings = try? await firebaseService.fetchNotificationSettings()
        guard settings?.isMilestoneEnabled != false else { return }

        if let milestone = GoalEngine.milestoneReached(
            goal: goal, currentValue: current, previousValue: previous
        ) {
            await notificationService.sendMilestoneNotification(
                percentage: milestone, goalType: goal.type
            )
        }
    }

    private func checkStreak() async {
        guard let notificationService else { return }
        let settings = try? await firebaseService.fetchNotificationSettings()
        guard settings?.isStreakEnabled != false else { return }

        await notificationService.sendStreakNotification(days: streak)
    }

    private func checkBadges() async {
        do {
            earnedBadges = try await firebaseService.fetchBadges()
            let newBadges = BadgeService.checkNewBadges(
                streak: streak,
                totalMeasurements: measurements.count,
                goal: activeGoal,
                goalProgress: goalProgress,
                existing: earnedBadges
            )
            for badge in newBadges {
                try await firebaseService.addBadge(badge)
            }
            newlyEarnedBadges = newBadges
            if !newBadges.isEmpty {
                earnedBadges = try await firebaseService.fetchBadges()
            }
        } catch {
            // Badge check failure is non-critical
        }
    }
}
