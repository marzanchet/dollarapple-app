import Foundation

public enum AwesomeAPIDecoder {
    private struct Raw: Decodable {
        let bid: String
        let pctChange: String?
        let timestamp: String
    }

    private static let posix = Locale(identifier: "en_US_POSIX")

    /// Decodes `json/last/A-BRL,B-BRL,...`: an object keyed by `"ABRL"`, `"BBRL"`.
    /// Pairs with a non-positive or unparseable bid are dropped; an empty result is an error.
    public static func decodeLast(_ data: Data) throws -> RatesSnapshot {
        let raw: [String: Raw]
        do { raw = try JSONDecoder().decode([String: Raw].self, from: data) }
        catch { throw QuoteError.badPayload }
        var quotes: [String: Quote] = [:]
        for (key, value) in raw where key.hasSuffix("BRL") && key.count > 3 {
            let code = String(key.dropLast(3))
            guard let bid = Decimal(string: value.bid, locale: posix), bid > 0,
                  let ts = TimeInterval(value.timestamp)
            else { continue }
            let pct = value.pctChange.flatMap { Decimal(string: $0, locale: posix) } ?? 0
            quotes[code] = Quote(code: code, bid: bid, pctChange: pct, timestamp: Date(timeIntervalSince1970: ts))
        }
        guard !quotes.isEmpty else { throw QuoteError.badPayload }
        return RatesSnapshot(quotes: quotes)
    }

    /// Decodes `json/daily/A-BRL/N`: an array, newest first. Returns points oldest first.
    public static func decodeDaily(_ data: Data) throws -> [HistoryPoint] {
        let raw: [Raw]
        do { raw = try JSONDecoder().decode([Raw].self, from: data) }
        catch { throw QuoteError.badPayload }
        let points = raw.compactMap { r -> HistoryPoint? in
            guard let bid = Decimal(string: r.bid, locale: posix), bid > 0,
                  let ts = TimeInterval(r.timestamp) else { return nil }
            return HistoryPoint(date: Date(timeIntervalSince1970: ts), bid: bid)
        }
        guard !points.isEmpty else { throw QuoteError.badPayload }
        return points.sorted { $0.date < $1.date }
    }
}
