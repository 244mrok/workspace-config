import Testing
import Foundation
@testable import HeroAcademia

@Suite("HealthDevice Model Tests")
struct HealthDeviceTests {

    @Test("HealthDevice initialization with defaults")
    func initDefaults() {
        let device = HealthDevice(type: .omron, name: "体組成計")

        #expect(device.id == nil)
        #expect(device.type == .omron)
        #expect(device.name == "体組成計")
        #expect(device.lastSyncDate == nil)
        #expect(device.isConnected == false)
    }

    @Test("HealthDevice initialization with all fields")
    func initAllFields() {
        let syncDate = Date()
        let device = HealthDevice(
            id: "device-1",
            type: .fitbit,
            name: "Fitbit Aria",
            lastSyncDate: syncDate,
            isConnected: true
        )

        #expect(device.id == "device-1")
        #expect(device.type == .fitbit)
        #expect(device.name == "Fitbit Aria")
        #expect(device.lastSyncDate == syncDate)
        #expect(device.isConnected == true)
    }

    @Test("DeviceType displayName")
    func displayName() {
        #expect(DeviceType.omron.displayName == "Omron")
        #expect(DeviceType.fitbit.displayName == "Fitbit")
        #expect(DeviceType.garmin.displayName == "Garmin")
        #expect(DeviceType.withings.displayName == "Withings")
        #expect(DeviceType.tanita.displayName == "TANITA")
    }

    @Test("DeviceType iconName is not empty")
    func iconName() {
        for type in DeviceType.allCases {
            #expect(!type.iconName.isEmpty)
        }
    }

    @Test("All device types are unavailable in MVP")
    func allUnavailable() {
        for type in DeviceType.allCases {
            #expect(!type.isAvailable)
            #expect(!type.statusMessage.isEmpty)
        }
    }

    @Test("DeviceType allCases has 4 types")
    func allCases() {
        #expect(DeviceType.allCases.count == 5)
    }

    @Test("HealthDevice equality")
    func equality() {
        let d1 = HealthDevice(id: "1", type: .omron, name: "A")
        let d2 = HealthDevice(id: "1", type: .omron, name: "A")
        let d3 = HealthDevice(id: "2", type: .fitbit, name: "B")

        #expect(d1 == d2)
        #expect(d1 != d3)
    }
}
