import Foundation
import WatchConnectivity

/// watchOS-side WatchConnectivity service that receives data from iPhone.
@MainActor
@Observable
final class WatchSessionService: NSObject {
    var watchData: WatchData?
    var isConnected = false

    @ObservationIgnored
    private var session: WCSession?

    override init() {
        super.init()
        // Load cached data immediately
        watchData = WatchData.loadFromCache()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    func sendWeightLog(weight: Double) {
        guard let session, session.activationState == .activated else { return }
        let message: [String: Any] = [
            "weight": weight,
            "timestamp": Date().timeIntervalSince1970
        ]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)

        // Optimistically update local data
        watchData?.latestWeight = weight
        watchData?.lastUpdated = Date()
        watchData?.saveToCache()
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            isConnected = activationState == .activated
            // Check for existing context
            if !session.receivedApplicationContext.isEmpty {
                if let data = WatchData.from(dictionary: session.receivedApplicationContext) {
                    watchData = data
                    data.saveToCache()
                }
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let data = WatchData.from(dictionary: applicationContext) else { return }
        Task { @MainActor in
            watchData = data
            data.saveToCache()
        }
    }
}
