import Foundation
import Observation

/// User preferences, persisted to UserDefaults on every change.
@MainActor @Observable
public final class Settings {
    public static let refreshIntervals = [60, 300, 900, 1800]

    private enum Key {
        static let bar = "settings.barCurrency"
        static let enabled = "settings.enabledCurrencies"
        static let showChange = "settings.showChangeInBar"
        static let interval = "settings.refreshInterval"
        static let alerts = "settings.alerts"
    }

    private let defaults: UserDefaults

    public var barCurrency: String {
        didSet {
            guard Currency.by(code: barCurrency) != nil, enabledCurrencies.contains(barCurrency) else {
                barCurrency = oldValue
                return
            }
            defaults.set(barCurrency, forKey: Key.bar)
        }
    }

    public private(set) var enabledCurrencies: [String] {
        didSet { defaults.set(enabledCurrencies, forKey: Key.enabled) }
    }

    public var showChangeInBar: Bool {
        didSet { defaults.set(showChangeInBar, forKey: Key.showChange) }
    }

    public var refreshInterval: Int {
        didSet {
            if !Self.refreshIntervals.contains(refreshInterval) {
                refreshInterval = Self.nearestInterval(refreshInterval)
                return
            }
            defaults.set(refreshInterval, forKey: Key.interval)
        }
    }

    public var alerts: [RateAlert] {
        didSet { Cache<[RateAlert]>(defaults: defaults, key: Key.alerts).save(alerts) }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let enabled = (defaults.stringArray(forKey: Key.enabled) ?? Currency.defaultEnabled)
            .filter { Currency.by(code: $0) != nil }
        let ordered = Self.catalogOrder(enabled.isEmpty ? Currency.defaultEnabled : enabled)
        self.enabledCurrencies = ordered
        let bar = defaults.string(forKey: Key.bar) ?? Currency.defaultBar
        self.barCurrency = ordered.contains(bar) ? bar : ordered[0]
        self.showChangeInBar = defaults.bool(forKey: Key.showChange)
        let interval = defaults.object(forKey: Key.interval) as? Int ?? 300
        self.refreshInterval = Self.refreshIntervals.contains(interval) ? interval : 300
        self.alerts = Cache<[RateAlert]>(defaults: defaults, key: Key.alerts).load() ?? []
    }

    /// Enables or disables a currency. Never leaves the list empty; keeps the bar currency valid.
    public func setEnabled(_ code: String, _ on: Bool) {
        guard Currency.by(code: code) != nil else { return }
        var list = enabledCurrencies
        if on {
            guard !list.contains(code) else { return }
            list.append(code)
        } else {
            guard list.count > 1 else { return }
            list.removeAll { $0 == code }
        }
        enabledCurrencies = Self.catalogOrder(list)
        if !enabledCurrencies.contains(barCurrency) {
            barCurrency = enabledCurrencies[0]
        }
    }

    public func isEnabled(_ code: String) -> Bool { enabledCurrencies.contains(code) }

    private static func catalogOrder(_ codes: [String]) -> [String] {
        Currency.all.map(\.code).filter { codes.contains($0) }
    }

    private static func nearestInterval(_ value: Int) -> Int {
        refreshIntervals.min { abs($0 - value) < abs($1 - value) } ?? 300
    }
}
