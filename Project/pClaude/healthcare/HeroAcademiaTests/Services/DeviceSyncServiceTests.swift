import Testing
import Foundation
@testable import HeroAcademia

@Suite("DeviceSyncService Tests")
struct DeviceSyncServiceTests {

    @Test("StubDeviceSyncService reports all types as unavailable")
    func unavailable() {
        let service = StubDeviceSyncService()
        for type in DeviceType.allCases {
            #expect(!service.isAvailable(for: type))
        }
    }

    @Test("StubDeviceSyncService connect throws notAvailable")
    func connectThrows() async {
        let service = StubDeviceSyncService()
        do {
            _ = try await service.connect(deviceType: .omron)
            Issue.record("Should have thrown")
        } catch let error as DeviceSyncError {
            #expect(error == .notAvailable)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("StubDeviceSyncService disconnect throws notAvailable")
    func disconnectThrows() async {
        let service = StubDeviceSyncService()
        do {
            try await service.disconnect(deviceId: "test-id")
            Issue.record("Should have thrown")
        } catch let error as DeviceSyncError {
            #expect(error == .notAvailable)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("StubDeviceSyncService syncMeasurements throws notAvailable")
    func syncThrows() async {
        let service = StubDeviceSyncService()
        do {
            _ = try await service.syncMeasurements(deviceId: "test-id")
            Issue.record("Should have thrown")
        } catch let error as DeviceSyncError {
            #expect(error == .notAvailable)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("StubOmronService reports SDK unavailable")
    func omronUnavailable() {
        let service = StubOmronService()
        #expect(!service.isSDKAvailable)
    }

    @Test("StubOmronService startPairing throws")
    func omronPairingThrows() async {
        let service = StubOmronService()
        do {
            _ = try await service.startPairing()
            Issue.record("Should have thrown")
        } catch let error as OmronServiceError {
            #expect(error == .sdkNotAvailable)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("StubOmronService fetchMeasurements throws")
    func omronFetchThrows() async {
        let service = StubOmronService()
        do {
            _ = try await service.fetchMeasurements()
            Issue.record("Should have thrown")
        } catch let error as OmronServiceError {
            #expect(error == .sdkNotAvailable)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("DeviceSyncError has localized descriptions")
    func errorDescriptions() {
        let errors: [DeviceSyncError] = [.notAvailable, .connectionFailed, .syncFailed, .deviceNotFound]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("OmronServiceError has localized descriptions")
    func omronErrorDescriptions() {
        let errors: [OmronServiceError] = [.sdkNotAvailable, .pairingFailed, .fetchFailed]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}
