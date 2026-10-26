import Foundation
@testable import DollarCore

func freshDefaults() -> UserDefaults {
    let name = "dollarapple.tests.\(UUID().uuidString)"
    let d = UserDefaults(suiteName: name)!
    d.removePersistentDomain(forName: name)
    return d
}

func quote(_ code: String, _ bid: String, pct: String = "0", ts: TimeInterval = 1) -> Quote {
    Quote(code: code, bid: Decimal(string: bid, locale: Locale(identifier: "en_US_POSIX"))!,
          pctChange: Decimal(string: pct, locale: Locale(identifier: "en_US_POSIX"))!,
          timestamp: Date(timeIntervalSince1970: ts))
}

func snapshot(_ quotes: Quote...) -> RatesSnapshot {
    RatesSnapshot(quotes: Dictionary(uniqueKeysWithValues: quotes.map { ($0.code, $0) }), fetchedAt: Date(timeIntervalSince1970: 100))
}
