import DollarCore
import Foundation

/// Everything the scenes need, created once at launch.
@MainActor
public final class AppEnvironment {
    public let settings: DollarCore.Settings
    public let store: RatesStore
    public let updater: any Updater
    let notifier: Notifier

    public init(updater: any Updater, client: any RatesClient = AwesomeAPIClient(), defaults: UserDefaults = .standard) {
        let settings = DollarCore.Settings(defaults: defaults)
        self.settings = settings
        self.store = RatesStore(client: client, settings: settings, defaults: defaults)
        self.updater = updater
        self.notifier = Notifier()

        store.onFired = { [weak self] fired in
            guard let self else { return }
            self.notifier.post(fired, snapshot: self.store.snapshot)
        }
        if !settings.alerts.isEmpty { notifier.requestAuthorization() }
        store.start()
        LaunchAtLogin.enableByDefaultIfUndecided()
    }
}
