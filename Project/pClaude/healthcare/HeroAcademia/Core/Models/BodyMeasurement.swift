import Foundation
import FirebaseFirestore

struct BodyMeasurement: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var date: Date
    var weight: Double?
    var bodyFatPercentage: Double?
    var bmi: Double?
    var muscleMass: Double?
    var visceralFatLevel: Int?
    var metabolicAge: Int?
    var source: MeasurementSource
    var deviceId: String?

    init(
        id: String? = nil,
        date: Date = Date(),
        weight: Double? = nil,
        bodyFatPercentage: Double? = nil,
        bmi: Double? = nil,
        muscleMass: Double? = nil,
        visceralFatLevel: Int? = nil,
        metabolicAge: Int? = nil,
        source: MeasurementSource = .manual,
        deviceId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.bodyFatPercentage = bodyFatPercentage
        self.bmi = bmi
        self.muscleMass = muscleMass
        self.visceralFatLevel = visceralFatLevel
        self.metabolicAge = metabolicAge
        self.source = source
        self.deviceId = deviceId
    }
}
