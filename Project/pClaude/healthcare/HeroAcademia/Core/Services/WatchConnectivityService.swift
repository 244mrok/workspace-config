import Foundation
import WatchConnectivity

/// iOS-side WatchConnectivity service that sends data to the Watch.
@MainActor
@Observable
final class WatchConnectivityService: NSObject {
    var isReachable = false

    @ObservationIgnored
    private var session: WCSession?

    private let firebaseService: FirebaseServiceProtocol?

    init(firebaseService: FirebaseServiceProtocol? = nil) {
        self.firebaseService = firebaseService
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    func sendWatchData(_ data: WatchData) {
        guard let session, session.activationState == .activated else { return }
        try? session.updateApplicationContext(data.toDictionary())
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            isReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        // Handle weight log from watch
        guard let weightValue = message["weight"] as? Double,
              let timestamp = message["timestamp"] as? TimeInterval else { return }

        let date = Date(timeIntervalSince1970: timestamp)
        let measurement = BodyMeasurement(date: date, weight: weightValue, source: .manual)

        Task { @MainActor in
            try? await firebaseService?.addMeasurement(measurement)
        }
    }
}
