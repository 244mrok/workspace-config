import Foundation

@MainActor
@Observable
final class DeviceViewModel {
    var connectedDevices: [HealthDevice] = []
    var isLoading = false
    var errorMessage: String?
    var showingPairingSheet = false
    var selectedDeviceType: DeviceType?

    private let firebaseService: FirebaseServiceProtocol
    private let syncService: DeviceSyncServiceProtocol

    init(firebaseService: FirebaseServiceProtocol, syncService: DeviceSyncServiceProtocol = StubDeviceSyncService()) {
        self.firebaseService = firebaseService
        self.syncService = syncService
    }

    var availableDeviceTypes: [DeviceType] {
        DeviceType.allCases
    }

    func loadDevices() async {
        isLoading = true
        errorMessage = nil

        do {
            connectedDevices = try await firebaseService.fetchDevices()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func connectDevice(type: DeviceType) async {
        guard syncService.isAvailable(for: type) else {
            errorMessage = type.statusMessage
            return
        }

        do {
            let device = try await syncService.connect(deviceType: type)
            try await firebaseService.addDevice(device)
            await loadDevices()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disconnectDevice(_ device: HealthDevice) async {
        guard let id = device.id else { return }

        do {
            try await syncService.disconnect(deviceId: id)
            try await firebaseService.deleteDevice(id: id)
            await loadDevices()
        } catch {
            // Even if sync service fails, remove from Firebase
            try? await firebaseService.deleteDevice(id: id)
            await loadDevices()
        }
    }

    func syncDevice(_ device: HealthDevice) async {
        guard let id = device.id else { return }

        do {
            _ = try await syncService.syncMeasurements(deviceId: id)
            var updated = device
            updated.lastSyncDate = Date()
            try await firebaseService.updateDevice(updated)
            await loadDevices()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
