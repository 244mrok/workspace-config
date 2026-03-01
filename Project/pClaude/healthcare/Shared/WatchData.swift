import Foundation

/// Data shared between iOS app and watchOS companion via WatchConnectivity.
struct WatchData: Codable, Equatable {
    var latestWeight: Double?
    var latestBodyFat: Double?
    var goalProgress: Double?
    var goalTargetValue: Double?
    var goalType: String?  // "weight" or "bodyFat"
    var goalDaysRemaining: Int?
    var streak: Int
    var lastUpdated: Date

    init(
        latestWeight: Double? = nil,
        latestBodyFat: Double? = nil,
        goalProgress: Double? = nil,
        goalTargetValue: Double? = nil,
        goalType: String? = nil,
        goalDaysRemaining: Int? = nil,
        streak: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.latestWeight = latestWeight
        self.latestBodyFat = latestBodyFat
        self.goalProgress = goalProgress
        self.goalTargetValue = goalTargetValue
        self.goalType = goalType
        self.goalDaysRemaining = goalDaysRemaining
        self.streak = streak
        self.lastUpdated = lastUpdated
    }

    /// Encode to dictionary for WCSession applicationContext.
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }

    /// Decode from WCSession applicationContext dictionary.
    static func from(dictionary: [String: Any]) -> WatchData? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary),
              let watchData = try? JSONDecoder().decode(WatchData.self, from: data) else {
            return nil
        }
        return watchData
    }

    // MARK: - UserDefaults Caching

    private static let cacheKey = "com.heroacademia.watchdata"

    func saveToCache() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }

    static func loadFromCache() -> WatchData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(WatchData.self, from: data)
    }
}
