import Foundation

// MARK: - Errors

enum OmronServiceError: LocalizedError {
    case sdkNotAvailable
    case pairingFailed
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .sdkNotAvailable:
            return "Omron Connect SDKが利用できません"
        case .pairingFailed:
            return "デバイスのペアリングに失敗しました"
        case .fetchFailed:
            return "測定データの取得に失敗しました"
        }
    }
}

// MARK: - Protocol

protocol OmronServiceProtocol {
    var isSDKAvailable: Bool { get }
    func startPairing() async throws -> HealthDevice
    func fetchMeasurements() async throws -> [BodyMeasurement]
}

// MARK: - Stub Implementation

final class StubOmronService: OmronServiceProtocol {
    var isSDKAvailable: Bool { false }

    func startPairing() async throws -> HealthDevice {
        throw OmronServiceError.sdkNotAvailable
    }

    func fetchMeasurements() async throws -> [BodyMeasurement] {
        throw OmronServiceError.sdkNotAvailable
    }
}
