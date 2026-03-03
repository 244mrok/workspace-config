import Foundation

@MainActor
@Observable
final class GoalViewModel {
    var goals: [Goal] = []
    var isLoading = false
    var errorMessage: String?

    // Input form fields
    var inputType: GoalType = .weight
    var inputTargetValue: String = ""
    var inputStartValue: String = ""
    var inputDeadline: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    // Edit mode
    var editingGoal: Goal?

    private let firebaseService: FirebaseServiceProtocol

    init(firebaseService: FirebaseServiceProtocol) {
        self.firebaseService = firebaseService
    }

    // MARK: - Computed

    var activeGoal: Goal? {
        goals.first { $0.isActive }
    }

    var activeGoalTypes: Set<GoalType> {
        Set(goals.filter(\.isActive).map(\.type))
    }

    /// The goal type not yet used by an active goal, if any.
    var availableType: GoalType? {
        GoalType.allCases.first { !activeGoalTypes.contains($0) }
    }

    // MARK: - Actions

    func loadGoals() async {
        isLoading = true
        errorMessage = nil

        do {
            goals = try await firebaseService.fetchActiveGoals()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addGoal() async {
        guard let target = Double(inputTargetValue),
              let start = Double(inputStartValue) else {
            errorMessage = "目標値と現在値を正しく入力してください"
            return
        }

        let goal = Goal(
            type: inputType,
            targetValue: target,
            startValue: start,
            deadline: inputDeadline
        )

        do {
            try await firebaseService.addGoal(goal)
            resetForm()
            await loadGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startEditing(_ goal: Goal) {
        editingGoal = goal
        inputType = goal.type
        inputTargetValue = String(format: "%.1f", goal.targetValue)
        inputStartValue = String(format: "%.1f", goal.startValue)
        inputDeadline = goal.deadline
        errorMessage = nil
    }

    func updateExistingGoal() async {
        guard let existing = editingGoal, let id = existing.id else { return }
        guard let target = Double(inputTargetValue) else {
            errorMessage = "目標値を正しく入力してください"
            return
        }

        let updated = Goal(
            id: id,
            type: existing.type,
            targetValue: target,
            startValue: existing.startValue,
            startDate: existing.startDate,
            deadline: inputDeadline,
            isActive: existing.isActive
        )

        do {
            try await firebaseService.updateGoal(updated)
            resetForm()
            await loadGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deactivateGoal(_ goal: Goal) async {
        guard let id = goal.id else { return }

        do {
            try await firebaseService.deactivateGoal(id: id)
            await loadGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetForm() {
        inputType = .weight
        inputTargetValue = ""
        inputStartValue = ""
        inputDeadline = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        editingGoal = nil
        errorMessage = nil
    }
}
