import Foundation

// MARK: - Errors

enum TanitaBLEError: LocalizedError {
    case bluetoothUnavailable
    case connectionFailed
    case deviceNotFound
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            return "Bluetoothが利用できません"
        case .connectionFailed:
            return "TANITAデバイスへの接続に失敗しました"
        case .deviceNotFound:
            return "TANITAデバイスが見つかりません"
        case .fetchFailed:
            return "測定データの取得に失敗しました"
        }
    }
}

// MARK: - Protocol

protocol TanitaBLEServiceProtocol {
    var isBluetoothAvailable: Bool { get }
    func startPairing() async throws -> HealthDevice
    func fetchMeasurements() async throws -> [BodyMeasurement]
}

// MARK: - Stub Implementation

final class StubTanitaBLEService: TanitaBLEServiceProtocol {
    var isBluetoothAvailable: Bool { false }

    func startPairing() async throws -> HealthDevice {
        throw TanitaBLEError.bluetoothUnavailable
    }

    func fetchMeasurements() async throws -> [BodyMeasurement] {
        throw TanitaBLEError.bluetoothUnavailable
    }
}
