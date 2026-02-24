import Foundation

enum MeasurementSource: String, Codable, CaseIterable {
    case manual
    case healthKit
    case omron
    case fitbit
    case garmin
    case withings

    var displayName: String {
        switch self {
        case .manual: return "手動入力"
        case .healthKit: return "HealthKit"
        case .omron: return "Omron"
        case .fitbit: return "Fitbit"
        case .garmin: return "Garmin"
        case .withings: return "Withings"
        }
    }
}
