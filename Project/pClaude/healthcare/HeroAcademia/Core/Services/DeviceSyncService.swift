import Foundation

// MARK: - Errors

enum DeviceSyncError: LocalizedError {
    case notAvailable
    case connectionFailed
    case syncFailed
    case deviceNotFound

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "このデバイスはまだ対応していません"
        case .connectionFailed:
            return "デバイスへの接続に失敗しました"
        case .syncFailed:
            return "データの同期に失敗しました"
        case .deviceNotFound:
            return "デバイスが見つかりません"
        }
    }
}

// MARK: - Protocol

protocol DeviceSyncServiceProtocol {
    func isAvailable(for deviceType: DeviceType) -> Bool
    func connect(deviceType: DeviceType) async throws -> HealthDevice
    func disconnect(deviceId: String) async throws
    func syncMeasurements(deviceId: String) async throws -> [BodyMeasurement]
}

// MARK: - Stub Implementation

final class StubDeviceSyncService: DeviceSyncServiceProtocol {
    func isAvailable(for deviceType: DeviceType) -> Bool {
        false
    }

    func connect(deviceType: DeviceType) async throws -> HealthDevice {
        throw DeviceSyncError.notAvailable
    }

    func disconnect(deviceId: String) async throws {
        throw DeviceSyncError.notAvailable
    }

    func syncMeasurements(deviceId: String) async throws -> [BodyMeasurement] {
        throw DeviceSyncError.notAvailable
    }
}
