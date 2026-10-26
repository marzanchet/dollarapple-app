import DollarCore
import Foundation
import UserNotifications

/// Posts macOS notifications for fired alerts. Inert when not running inside an app bundle.
@MainActor
final class Notifier {
    private let delegate = ForegroundDelegate()

    private var center: UNUserNotificationCenter? {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return nil }
        return .current()
    }

    init() {
        center?.delegate = delegate
    }

    func requestAuthorization() {
        center?.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func authorizationStatus() async -> UNAuthorizationStatus? {
        guard let center else { return nil }
        return await center.notificationSettings().authorizationStatus
    }

    func post(_ fired: [RateAlert], snapshot: RatesSnapshot?) {
        guard let center else { return }
        for alert in fired {
            guard let quote = snapshot?[alert.code] else { continue }
            let content = UNMutableNotificationContent()
            let key = alert.direction == .above ? "notification.above" : "notification.below"
            content.title = L(key, currencyName(alert.code), MoneyFormatter.brl(alert.threshold))
            content.body = L("notification.body", MoneyFormatter.brl(quote.bid))
            content.sound = .default
            let id = "\(alert.id.uuidString)-\(Int(Date().timeIntervalSince1970))"
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
        }
    }
}

/// Shows banners even when the app is frontmost.
private final class ForegroundDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}
