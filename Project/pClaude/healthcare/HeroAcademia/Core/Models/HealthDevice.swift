import Foundation
import FirebaseFirestore

enum DeviceType: String, Codable, CaseIterable, Identifiable {
    case omron
    case fitbit
    case garmin
    case withings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .omron: return "Omron"
        case .fitbit: return "Fitbit"
        case .garmin: return "Garmin"
        case .withings: return "Withings"
        }
    }

    var iconName: String {
        switch self {
        case .omron: return "scalemass"
        case .fitbit: return "applewatch"
        case .garmin: return "applewatch.side.right"
        case .withings: return "scalemass.fill"
        }
    }

    var isAvailable: Bool {
        false // All devices are stubs for MVP
    }

    var statusMessage: String {
        "近日対応予定"
    }
}

struct HealthDevice: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var type: DeviceType
    var name: String
    var lastSyncDate: Date?
    var isConnected: Bool

    init(
        id: String? = nil,
        type: DeviceType,
        name: String,
        lastSyncDate: Date? = nil,
        isConnected: Bool = false
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.lastSyncDate = lastSyncDate
        self.isConnected = isConnected
    }
}
