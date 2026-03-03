import Foundation

@MainActor
@Observable
final class DashboardViewModel {
    var measurements: [BodyMeasurement] = []
    var activeGoals: [Goal] = []
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

    /// Backward compatibility — first active goal (used by WatchData)
    var activeGoal: Goal? { activeGoals.first }

    var weightGoal: Goal? { activeGoals.first { $0.type == .weight } }
    var bodyFatGoal: Goal? { activeGoals.first { $0.type == .bodyFat } }

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

    var estimatedTDEE: Double? {
        guard let weight = latestWeight,
              let profile = userProfile,
              let height = profile.height,
              let birthday = profile.birthday,
              let gender = profile.gender else { return nil }
        let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
        guard age > 0 else { return nil }
        let bmr = GoalEngine.bmr(
            weightKg: weight, heightCm: height, age: age,
            gender: gender, bodyFatPercentage: latestBodyFat
        )
        return GoalEngine.tdee(bmr: bmr, activityLevel: .light)
    }

    // MARK: - Per-goal helpers

    func goalProgress(for goal: Goal) -> Double? {
        switch goal.type {
        case .weight:
            guard let w = latestWeight else { return nil }
            return goal.progressPercentage(currentValue: w)
        case .bodyFat:
            guard let bf = latestBodyFat else { return nil }
            return goal.progressPercentage(currentValue: bf)
        }
    }

    func currentGoalValue(for goal: Goal) -> Double? {
        switch goal.type {
        case .weight: return latestWeight
        case .bodyFat: return latestBodyFat
        }
    }

    func projectedDate(for goal: Goal) -> Date? {
        GoalEngine.projectedCompletionDate(goal: goal, recentMeasurements: measurements)
    }

    /// Backward compatibility — uses first active goal
    var goalProgress: Double? {
        guard let goal = activeGoal else { return nil }
        return goalProgress(for: goal)
    }

    var currentGoalValue: Double? {
        guard let goal = activeGoal else { return nil }
        return currentGoalValue(for: goal)
    }

    var projectedDate: Date? {
        guard let goal = activeGoal else { return nil }
        return projectedDate(for: goal)
    }

    var streak: Int {
        GoalEngine.streak(from: measurements)
    }

    // MARK: - Actions

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            // Capture previous values per goal type for milestone checks
            var previousValues: [GoalType: Double] = [:]
            for goal in activeGoals {
                if let val = currentGoalValue(for: goal) {
                    previousValues[goal.type] = val
                }
            }

            async let fetchedMeasurements = firebaseService.fetchMeasurements(limit: 30)
            async let fetchedGoals = firebaseService.fetchActiveGoals()
            async let fetchedProfile = firebaseService.fetchUserProfile()

            measurements = try await fetchedMeasurements
            activeGoals = try await fetchedGoals
            userProfile = try await fetchedProfile

            // Check milestone notifications for each goal
            for goal in activeGoals {
                await checkMilestone(for: goal, previousValue: previousValues[goal.type])
            }

            // Check streak notifications
            await checkStreak()

            // Check badges
            await checkBadges()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func checkMilestone(for goal: Goal, previousValue: Double?) async {
        guard let current = currentGoalValue(for: goal),
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
            var allNewBadges: [Badge] = []

            // Check per-goal badges (and non-goal badges on first iteration)
            let goalsToCheck: [Goal?] = activeGoals.isEmpty ? [nil] : activeGoals.map { $0 as Goal? }
            for goal in goalsToCheck {
                let progress = goal.flatMap { goalProgress(for: $0) }
                let newBadges = BadgeService.checkNewBadges(
                    streak: streak,
                    totalMeasurements: measurements.count,
                    goal: goal,
                    goalProgress: progress,
                    existing: earnedBadges + allNewBadges
                )
                allNewBadges.append(contentsOf: newBadges)
            }

            for badge in allNewBadges {
                try await firebaseService.addBadge(badge)
            }
            newlyEarnedBadges = allNewBadges
            if !allNewBadges.isEmpty {
                earnedBadges = try await firebaseService.fetchBadges()
            }
        } catch {
            // Badge check failure is non-critical
        }
    }
}
