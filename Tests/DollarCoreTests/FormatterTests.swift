import Foundation
import Testing
@testable import DollarCore

@Suite struct FormatterTests {
    let br = Locale(identifier: "pt_BR")
    let us = Locale(identifier: "en_US")
    func d(_ s: String) -> Decimal { Decimal(string: s, locale: Locale(identifier: "en_US_POSIX"))! }

    @Test func priceTwoDecimals() {
        #expect(MoneyFormatter.price(d("5.1259"), locale: br) == "5,13")
        #expect(MoneyFormatter.price(d("5.1259"), locale: us) == "5.13")
    }
    @Test func priceGrouping() {
        #expect(MoneyFormatter.price(d("1234.5"), locale: br) == "1.234,50")
        #expect(MoneyFormatter.price(d("1234.5"), locale: us) == "1,234.50")
    }
    @Test func priceLargeDropsCents() {
        #expect(MoneyFormatter.price(d("409853"), locale: br) == "409.853")
        #expect(MoneyFormatter.price(d("409853.7"), locale: us) == "409,854")
    }
    @Test func priceSubUnitFourDecimals() {
        #expect(MoneyFormatter.price(d("0.00339173"), locale: br) == "0,0034")
        #expect(MoneyFormatter.price(d("0.0333"), locale: us) == "0.0333")
    }
    @Test func brl() {
        #expect(MoneyFormatter.brl(d("5.1259"), locale: br) == "R$ 5,13")
        #expect(MoneyFormatter.brl(d("5.1259"), locale: us) == "R$ 5.13")
    }
    @Test func parseBR() {
        #expect(MoneyFormatter.parse("5,13", locale: br) == d("5.13"))
        #expect(MoneyFormatter.parse("1.234,56", locale: br) == d("1234.56"))
        #expect(MoneyFormatter.parse("5.13", locale: br) == d("5.13"))
    }
    @Test func parseUS() {
        #expect(MoneyFormatter.parse("5.13", locale: us) == d("5.13"))
        #expect(MoneyFormatter.parse("1,234.56", locale: us) == d("1234.56"))
        #expect(MoneyFormatter.parse("5,13", locale: us) == d("5.13"))
    }
    @Test func parseAmbiguousGroupingFollowsLocale() {
        #expect(MoneyFormatter.parse("1.234", locale: br) == d("1234"))
        #expect(MoneyFormatter.parse("1.234", locale: us) == d("1.234"))
        #expect(MoneyFormatter.parse("1,234", locale: us) == d("1234"))
        #expect(MoneyFormatter.parse("1,234", locale: br) == d("1.234"))
    }
    @Test func parseSymbolsAndJunk() {
        #expect(MoneyFormatter.parse(" R$ 10 ", locale: br) == Decimal(10))
        #expect(MoneyFormatter.parse("", locale: br) == nil)
        #expect(MoneyFormatter.parse("abc", locale: br) == nil)
    }
    @Test func percent() {
        #expect(MoneyFormatter.percent(d("0.019515"), locale: br) == "+0,02%")
        #expect(MoneyFormatter.percent(d("-1.236"), locale: us) == "-1.24%")
        #expect(MoneyFormatter.percent(0, locale: br) == "0,00%")
    }
    @Test func time() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        let date = cal.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 14, minute: 5))!
        #expect(MoneyFormatter.time(date, timeZone: cal.timeZone, locale: br) == "14:05")
    }
}

@Suite struct ConverterTests {
    let rate = Decimal(string: "5.1259")!
    @Test func brlFromForeign() { #expect(Converter.toBRL(amount: 10, rate: rate) == Decimal(string: "51.26")) }
    @Test func foreignFromBRL() { #expect(Converter.fromBRL(brl: Decimal(string: "51.26")!, rate: rate) == Decimal(string: "10.00")) }
    @Test func zeroRate() { #expect(Converter.fromBRL(brl: 10, rate: 0) == nil) }
    @Test func satoshiScaleKeepsPrecision() {
        // R$ 100 in BTC at R$ 409.853 is 0.00024399 BTC; conversion keeps 8 decimals for tiny results.
        #expect(Converter.fromBRL(brl: 100, rate: Decimal(409853)) == Decimal(string: "0.00024399"))
    }
}
