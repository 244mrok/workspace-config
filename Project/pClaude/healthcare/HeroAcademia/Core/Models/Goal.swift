import Foundation
import FirebaseFirestore

enum GoalType: String, Codable, CaseIterable {
    case weight
    case bodyFat

    var displayName: String {
        switch self {
        case .weight: return "体重"
        case .bodyFat: return "体脂肪率"
        }
    }

    var unit: String {
        switch self {
        case .weight: return "kg"
        case .bodyFat: return "%"
        }
    }
}

struct Goal: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var type: GoalType
    var targetValue: Double
    var startValue: Double
    var startDate: Date
    var deadline: Date
    var isActive: Bool

    init(
        id: String? = nil,
        type: GoalType,
        targetValue: Double,
        startValue: Double,
        startDate: Date = Date(),
        deadline: Date,
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.targetValue = targetValue
        self.startValue = startValue
        self.startDate = startDate
        self.deadline = deadline
        self.isActive = isActive
    }

    var totalChange: Double {
        targetValue - startValue
    }

    var dailyPace: Double {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: deadline).day ?? 1
        guard days > 0 else { return 0 }
        return totalChange / Double(days)
    }

    var progressPercentage: Double {
        guard totalChange != 0 else { return 0 }
        // This would need current value passed in; placeholder
        return 0
    }

    func progressPercentage(currentValue: Double) -> Double {
        guard totalChange != 0 else { return 0 }
        let currentChange = currentValue - startValue
        return min(max(currentChange / totalChange * 100, 0), 100)
    }
}
