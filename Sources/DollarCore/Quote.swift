import Foundation

/// One currency priced in BRL at a point in time.
public struct Quote: Sendable, Equatable, Codable {
    public let code: String
    public let bid: Decimal
    public let pctChange: Decimal
    public let timestamp: Date

    public init(code: String, bid: Decimal, pctChange: Decimal, timestamp: Date) {
        self.code = code
        self.bid = bid
        self.pctChange = pctChange
        self.timestamp = timestamp
    }
}

/// Every quote returned by one fetch, keyed by currency code.
public struct RatesSnapshot: Sendable, Equatable, Codable {
    public var quotes: [String: Quote]
    public let fetchedAt: Date

    public init(quotes: [String: Quote], fetchedAt: Date = Date()) {
        self.quotes = quotes
        self.fetchedAt = fetchedAt
    }

    public subscript(code: String) -> Quote? { quotes[code] }

    /// Quotes in catalog order, restricted to `codes`.
    public func ordered(_ codes: [String]) -> [Quote] {
        codes.compactMap { quotes[$0] }
    }
}

public struct HistoryPoint: Sendable, Equatable, Codable {
    public let date: Date
    public let bid: Decimal

    public init(date: Date, bid: Decimal) {
        self.date = date
        self.bid = bid
    }
}

public enum QuoteError: Error, Equatable {
    case badPayload
    case http(Int)

    /// Stable identifier the UI maps to a localized message.
    public var code: String {
        switch self {
        case .badPayload: "badPayload"
        case .http(let status): "http.\(status)"
        }
    }
}
