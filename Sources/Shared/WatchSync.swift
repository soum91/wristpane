import Foundation
import WatchConnectivity

/// Transfers settings between the paired apps. Each device keeps its own copy.
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    private var receive: (([String: Any]) -> Void)?
    private var pending: [String: Any]?

    func activate(receive: (([String: Any]) -> Void)? = nil) {
        if let receive { self.receive = receive }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        if WCSession.default.activationState == .notActivated {
            WCSession.default.activate()
        }
    }

    func send(configuration: [String: Any]) {
        guard WCSession.isSupported() else { return }
        if WCSession.default.activationState == .activated {
            try? WCSession.default.updateApplicationContext(configuration)
        } else {
            pending = configuration
            activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated, let pending {
            try? session.updateApplicationContext(pending)
            self.pending = nil
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.receive?(applicationContext)
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
