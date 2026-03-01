import Foundation

/// Stateless utility for badge evaluation.
struct BadgeService {

    /// Check which new badges should be awarded based on current stats.
    /// Returns only badges not already in the `existing` set.
    static func checkNewBadges(
        streak: Int,
        totalMeasurements: Int,
        goal: Goal?,
        goalProgress: Double?,
        existing: [Badge]
    ) -> [Badge] {
        let earnedTypes = Set(existing.map(\.type))
        var newBadges: [Badge] = []

        // Streak badges
        let streakMap: [(Int, BadgeType)] = [
            (7, .streak7), (14, .streak14), (30, .streak30),
            (60, .streak60), (100, .streak100), (365, .streak365)
        ]
        for (threshold, badgeType) in streakMap {
            if streak >= threshold && !earnedTypes.contains(badgeType) {
                newBadges.append(Badge(type: badgeType))
            }
        }

        // Measurement count badges
        if totalMeasurements >= 1 && !earnedTypes.contains(.firstMeasurement) {
            newBadges.append(Badge(type: .firstMeasurement))
        }
        if totalMeasurements >= 50 && !earnedTypes.contains(.measurements50) {
            newBadges.append(Badge(type: .measurements50))
        }
        if totalMeasurements >= 100 && !earnedTypes.contains(.measurements100) {
            newBadges.append(Badge(type: .measurements100))
        }

        // Goal progress badges
        if let goal, let progress = goalProgress {
            let goalBadges: [(Double, BadgeType)] = [
                (25, .goalProgress25), (50, .goalProgress50),
                (75, .goalProgress75), (100, .goalProgress100)
            ]
            for (threshold, badgeType) in goalBadges {
                if progress >= threshold && !earnedTypes.contains(badgeType) {
                    newBadges.append(Badge(type: badgeType, goalId: goal.id))
                }
            }
        }

        return newBadges
    }
}
