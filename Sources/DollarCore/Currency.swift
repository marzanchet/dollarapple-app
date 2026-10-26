import Foundation

/// A quote currency priced in BRL. `nameKey` is a localization key resolved by the UI.
public struct Currency: Sendable, Hashable, Codable, Identifiable {
    public let code: String
    public let symbol: String
    public let nameKey: String

    public var id: String { code }

    public static let all: [Currency] = [
        Currency(code: "USD", symbol: "US$", nameKey: "currency.USD"),
        Currency(code: "EUR", symbol: "€", nameKey: "currency.EUR"),
        Currency(code: "GBP", symbol: "£", nameKey: "currency.GBP"),
        Currency(code: "BTC", symbol: "₿", nameKey: "currency.BTC"),
        Currency(code: "ARS", symbol: "AR$", nameKey: "currency.ARS"),
        Currency(code: "CAD", symbol: "CA$", nameKey: "currency.CAD"),
        Currency(code: "AUD", symbol: "AU$", nameKey: "currency.AUD"),
        Currency(code: "JPY", symbol: "¥", nameKey: "currency.JPY"),
        Currency(code: "CHF", symbol: "CHF", nameKey: "currency.CHF"),
        Currency(code: "CNY", symbol: "CN¥", nameKey: "currency.CNY"),
    ]

    public static let defaultEnabled: [String] = ["USD", "EUR", "BTC"]
    public static let defaultBar = "USD"

    public static func by(code: String) -> Currency? {
        all.first { $0.code == code }
    }
}
