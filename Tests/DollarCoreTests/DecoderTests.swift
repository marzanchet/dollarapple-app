import Foundation
import Testing
@testable import DollarCore

func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

@Suite struct DecoderTests {
    @Test func decodesSinglePair() throws {
        let snap = try AwesomeAPIDecoder.decodeLast(try fixture("usd-brl"))
        let usd = try #require(snap["USD"])
        #expect(usd.code == "USD")
        #expect(usd.bid == Decimal(string: "5.1259"))
        #expect(usd.pctChange == Decimal(string: "0.019515"))
        #expect(usd.timestamp == Date(timeIntervalSince1970: 1_788_763_668))
        #expect(snap.quotes.count == 1)
    }

    @Test func decodesTenPairs() throws {
        let snap = try AwesomeAPIDecoder.decodeLast(try fixture("last-multi"))
        #expect(snap.quotes.count == 10)
        #expect(snap["BTC"]?.bid == Decimal(string: "409853"))
        #expect(snap["ARS"]?.bid == Decimal(string: "0.00339173"))
        #expect(Set(snap.quotes.keys) == Set(Currency.all.map(\.code)))
    }

    @Test func dropsZeroBidPairInsteadOfFailing() throws {
        let json = Data(#"{"USDBRL":{"bid":"5.1","pctChange":"0","timestamp":"1"},"EURBRL":{"bid":"0","pctChange":"0","timestamp":"1"}}"#.utf8)
        let snap = try AwesomeAPIDecoder.decodeLast(json)
        #expect(snap.quotes.count == 1)
        #expect(snap["USD"] != nil)
    }

    @Test func emptyOrGarbageThrows() {
        #expect(throws: QuoteError.badPayload) { try AwesomeAPIDecoder.decodeLast(Data("nope".utf8)) }
        #expect(throws: QuoteError.badPayload) { try AwesomeAPIDecoder.decodeLast(Data("{}".utf8)) }
        #expect(throws: QuoteError.badPayload) {
            try AwesomeAPIDecoder.decodeLast(Data(#"{"USDBRL":{"bid":"0","pctChange":"0","timestamp":"1"}}"#.utf8))
        }
    }

    @Test func decodesDailyHistorySortedAscending() throws {
        let points = try AwesomeAPIDecoder.decodeDaily(try fixture("daily-usd"))
        #expect(points.count == 30)
        #expect(zip(points, points.dropFirst()).allSatisfy { $0.date <= $1.date })
        #expect(points.last?.bid == Decimal(string: "5.1259"))
    }

    @Test func dailyGarbageThrows() {
        #expect(throws: QuoteError.badPayload) { try AwesomeAPIDecoder.decodeDaily(Data("{}".utf8)) }
    }
}

@Suite struct CurrencyTests {
    @Test func catalogHasTenUniqueCodes() {
        #expect(Currency.all.count == 10)
        #expect(Set(Currency.all.map(\.code)).count == 10)
    }
    @Test func lookup() {
        #expect(Currency.by(code: "EUR")?.symbol == "€")
        #expect(Currency.by(code: "XXX") == nil)
    }
    @Test func defaultsAreValid() {
        #expect(Currency.defaultEnabled == ["USD", "EUR", "BTC"])
        #expect(Currency.defaultEnabled.allSatisfy { Currency.by(code: $0) != nil })
    }
}
