import Foundation
import FirebaseFirestore

enum BadgeType: String, Codable, CaseIterable {
    // Streak badges
    case streak7
    case streak14
    case streak30
    case streak60
    case streak100
    case streak365

    // Goal progress badges
    case goalProgress25
    case goalProgress50
    case goalProgress75
    case goalProgress100

    // Measurement count badges
    case firstMeasurement
    case measurements50
    case measurements100

    var displayName: String {
        switch self {
        case .streak7: return "1週間連続"
        case .streak14: return "2週間連続"
        case .streak30: return "30日連続"
        case .streak60: return "60日連続"
        case .streak100: return "100日連続"
        case .streak365: return "365日連続"
        case .goalProgress25: return "目標25%達成"
        case .goalProgress50: return "目標50%達成"
        case .goalProgress75: return "目標75%達成"
        case .goalProgress100: return "目標達成！"
        case .firstMeasurement: return "はじめの一歩"
        case .measurements50: return "50回計測"
        case .measurements100: return "100回計測"
        }
    }

    var iconName: String {
        switch self {
        case .streak7: return "flame"
        case .streak14: return "flame"
        case .streak30: return "flame.fill"
        case .streak60: return "flame.fill"
        case .streak100: return "flame.circle.fill"
        case .streak365: return "flame.circle.fill"
        case .goalProgress25: return "flag"
        case .goalProgress50: return "flag.fill"
        case .goalProgress75: return "star"
        case .goalProgress100: return "star.fill"
        case .firstMeasurement: return "heart.fill"
        case .measurements50: return "chart.bar.fill"
        case .measurements100: return "chart.bar.fill"
        }
    }

    var iconColor: String {
        switch self {
        case .streak7, .streak14: return "orange"
        case .streak30, .streak60: return "red"
        case .streak100, .streak365: return "purple"
        case .goalProgress25, .goalProgress50: return "blue"
        case .goalProgress75, .goalProgress100: return "green"
        case .firstMeasurement: return "pink"
        case .measurements50, .measurements100: return "teal"
        }
    }
}

struct Badge: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var type: BadgeType
    var earnedDate: Date
    var goalId: String?

    init(
        id: String? = nil,
        type: BadgeType,
        earnedDate: Date = Date(),
        goalId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.earnedDate = earnedDate
        self.goalId = goalId
    }
}
