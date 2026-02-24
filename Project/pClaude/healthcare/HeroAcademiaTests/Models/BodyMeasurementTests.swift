import Testing
import Foundation
import FirebaseFirestore
@testable import HeroAcademia

@Suite("BodyMeasurement Tests")
struct BodyMeasurementTests {

    @Test("Create measurement with all fields")
    func createMeasurementWithAllFields() {
        let date = Date()
        let measurement = BodyMeasurement(
            date: date,
            weight: 70.5,
            bodyFatPercentage: 20.3,
            bmi: 23.1,
            muscleMass: 55.0,
            visceralFatLevel: 8,
            metabolicAge: 30,
            source: .manual,
            deviceId: "test-device"
        )

        #expect(measurement.weight == 70.5)
        #expect(measurement.bodyFatPercentage == 20.3)
        #expect(measurement.bmi == 23.1)
        #expect(measurement.muscleMass == 55.0)
        #expect(measurement.visceralFatLevel == 8)
        #expect(measurement.metabolicAge == 30)
        #expect(measurement.source == .manual)
        #expect(measurement.deviceId == "test-device")
    }

    @Test("Create measurement with minimal fields")
    func createMeasurementMinimal() {
        let measurement = BodyMeasurement(weight: 65.0)

        #expect(measurement.weight == 65.0)
        #expect(measurement.bodyFatPercentage == nil)
        #expect(measurement.bmi == nil)
        #expect(measurement.source == .manual)
    }

    @Test("Measurement source display names")
    func measurementSourceDisplayNames() {
        #expect(MeasurementSource.manual.displayName == "手動入力")
        #expect(MeasurementSource.healthKit.displayName == "HealthKit")
        #expect(MeasurementSource.omron.displayName == "Omron")
        #expect(MeasurementSource.fitbit.displayName == "Fitbit")
        #expect(MeasurementSource.garmin.displayName == "Garmin")
        #expect(MeasurementSource.withings.displayName == "Withings")
    }

    @Test("Firestore encoding produces correct fields")
    func firestoreEncoding() throws {
        let measurement = BodyMeasurement(
            date: Date(timeIntervalSince1970: 1700000000),
            weight: 70.5,
            bodyFatPercentage: 20.3,
            source: .healthKit
        )

        let encoded = try Firestore.Encoder().encode(measurement)

        #expect(encoded["weight"] as? Double == 70.5)
        #expect(encoded["bodyFatPercentage"] as? Double == 20.3)
        #expect(encoded["source"] as? String == "healthKit")
    }
}
