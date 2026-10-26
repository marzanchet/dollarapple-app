import Foundation
import Testing
@testable import DollarCore

@MainActor @Suite struct SettingsTests {
    @Test func defaults() {
        let s = Settings(defaults: freshDefaults())
        #expect(s.barCurrency == "USD")
        #expect(s.enabledCurrencies == ["USD", "EUR", "BTC"])
        #expect(s.showChangeInBar == false)
        #expect(s.refreshInterval == 300)
        #expect(s.alerts.isEmpty)
    }

    @Test func persistsAcrossInstances() {
        let d = freshDefaults()
        let a = Settings(defaults: d)
        a.barCurrency = "EUR"
        a.showChangeInBar = true
        a.refreshInterval = 60
        a.setEnabled("GBP", true)
        a.alerts = [RateAlert(code: "USD", direction: .above, threshold: 6)]
        let b = Settings(defaults: d)
        #expect(b.barCurrency == "EUR")
        #expect(b.showChangeInBar == true)
        #expect(b.refreshInterval == 60)
        #expect(b.enabledCurrencies == ["USD", "EUR", "GBP", "BTC"])
        #expect(b.alerts.count == 1 && b.alerts[0].code == "USD")
    }

    @Test func enabledKeepsCatalogOrder() {
        let s = Settings(defaults: freshDefaults())
        s.setEnabled("JPY", true)
        s.setEnabled("GBP", true)
        #expect(s.enabledCurrencies == ["USD", "EUR", "GBP", "BTC", "JPY"])
    }

    @Test func disablingBarCurrencyMovesBarToFirstEnabled() {
        let s = Settings(defaults: freshDefaults())
        s.setEnabled("USD", false)
        #expect(s.barCurrency == "EUR")
        #expect(s.enabledCurrencies == ["EUR", "BTC"])
    }

    @Test func cannotDisableLastCurrency() {
        let s = Settings(defaults: freshDefaults())
        s.setEnabled("EUR", false); s.setEnabled("BTC", false)
        s.setEnabled("USD", false)
        #expect(s.enabledCurrencies == ["USD"])
        #expect(s.barCurrency == "USD")
    }

    @Test func unknownCodeIgnored() {
        let s = Settings(defaults: freshDefaults())
        s.setEnabled("XXX", true)
        s.barCurrency = "XXX"
        #expect(s.enabledCurrencies == ["USD", "EUR", "BTC"])
        #expect(s.barCurrency == "USD")
    }

    @Test func refreshIntervalClampedToAllowed() {
        let s = Settings(defaults: freshDefaults())
        s.refreshInterval = 7
        #expect(s.refreshInterval == 60)
        #expect(Settings.refreshIntervals == [60, 300, 900, 1800])
    }
}
