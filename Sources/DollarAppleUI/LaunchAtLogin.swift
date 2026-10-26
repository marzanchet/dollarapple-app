import Foundation
import ServiceManagement

enum LaunchAtLogin {
    private static let decidedKey = "launchAtLoginDecided"

    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    /// Returns false when the system refused (for example when running outside an app bundle).
    @discardableResult
    static func set(_ enabled: Bool) -> Bool {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            UserDefaults.standard.set(true, forKey: decidedKey)
            NSLog("DollarApple: SMAppService %@ ok, status now %d", enabled ? "register" : "unregister", SMAppService.mainApp.status.rawValue)
            return true
        } catch {
            NSLog("DollarApple: SMAppService %@ failed: %@", enabled ? "register" : "unregister", String(describing: error))
            return false
        }
    }

    /// Default on: the first time the app runs from a fixed location it registers itself.
    /// Once the user has toggled it (or the first registration succeeded), we never touch it again.
    static func enableByDefaultIfUndecided() {
        guard !UserDefaults.standard.bool(forKey: decidedKey) else { return }
        let status = SMAppService.mainApp.status
        NSLog("DollarApple: login item status at launch = %d", status.rawValue)
        guard status == .notRegistered || status == .notFound else { return }
        set(true)
    }
}
