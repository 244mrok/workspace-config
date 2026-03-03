import Testing
import Foundation
@testable import HeroAcademia

@Suite("DeviceViewModel Tests")
struct DeviceViewModelTests {

    @Test("Initial state")
    @MainActor
    func initialState() {
        let firebase = MockFirebaseService()
        let vm = DeviceViewModel(firebaseService: firebase)

        #expect(vm.connectedDevices.isEmpty)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
        #expect(!vm.showingPairingSheet)
    }

    @Test("availableDeviceTypes returns all types")
    @MainActor
    func availableTypes() {
        let firebase = MockFirebaseService()
        let vm = DeviceViewModel(firebaseService: firebase)

        #expect(vm.availableDeviceTypes.count == 5)
    }

    @Test("loadDevices fetches from firebase")
    @MainActor
    func loadDevices() async {
        let firebase = MockFirebaseService()
        let device = TestFixtures.device(id: "d1", type: .omron, name: "Omron Scale")
        firebase.devices = [device]

        let vm = DeviceViewModel(firebaseService: firebase)
        await vm.loadDevices()

        #expect(vm.connectedDevices.count == 1)
        #expect(vm.connectedDevices.first?.name == "Omron Scale")
    }

    @Test("loadDevices handles errors")
    @MainActor
    func loadError() async {
        let firebase = MockFirebaseService()
        firebase.shouldThrowError = true

        let vm = DeviceViewModel(firebaseService: firebase)
        await vm.loadDevices()

        #expect(vm.errorMessage != nil)
    }

    @Test("connectDevice shows error for unavailable types")
    @MainActor
    func connectUnavailable() async {
        let firebase = MockFirebaseService()
        let vm = DeviceViewModel(firebaseService: firebase)

        await vm.connectDevice(type: .omron)

        #expect(vm.errorMessage != nil)
    }

    @Test("disconnectDevice removes device")
    @MainActor
    func disconnect() async {
        let firebase = MockFirebaseService()
        let device = TestFixtures.device(id: "d1", type: .omron, name: "Test")
        firebase.devices = [device]

        let vm = DeviceViewModel(firebaseService: firebase)
        await vm.loadDevices()
        #expect(vm.connectedDevices.count == 1)

        await vm.disconnectDevice(device)
        #expect(vm.connectedDevices.isEmpty)
    }

    @Test("syncDevice sets error for stub service")
    @MainActor
    func syncError() async {
        let firebase = MockFirebaseService()
        let device = TestFixtures.device(id: "d1")
        firebase.devices = [device]

        let vm = DeviceViewModel(firebaseService: firebase)
        await vm.syncDevice(device)

        #expect(vm.errorMessage != nil)
    }

    @Test("disconnectDevice handles nil id gracefully")
    @MainActor
    func disconnectNilId() async {
        let firebase = MockFirebaseService()
        let device = TestFixtures.device(id: nil)

        let vm = DeviceViewModel(firebaseService: firebase)
        await vm.disconnectDevice(device)

        // Should not crash
        #expect(vm.errorMessage == nil)
    }
}
