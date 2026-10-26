import Foundation
import Testing
@testable import DollarCore

@Suite struct AlertTests {
    @Test func aboveFiresOnceThenRearmsBelow() {
        var alerts = [RateAlert(code: "USD", direction: .above, threshold: 5)]
        var r = AlertEvaluator.evaluate(alerts, snapshot: snapshot(quote("USD", "5.2")))
        #expect(r.fired.map(\.id) == alerts.map(\.id))
        #expect(r.updated[0].isArmed == false)
        alerts = r.updated
        r = AlertEvaluator.evaluate(alerts, snapshot: snapshot(quote("USD", "5.3")))
        #expect(r.fired.isEmpty)
        #expect(r.updated[0].isArmed == false)
        alerts = r.updated
        r = AlertEvaluator.evaluate(alerts, snapshot: snapshot(quote("USD", "4.9")))
        #expect(r.fired.isEmpty)
        #expect(r.updated[0].isArmed == true)
        alerts = r.updated
        r = AlertEvaluator.evaluate(alerts, snapshot: snapshot(quote("USD", "5.0")))
        #expect(r.fired.count == 1)
    }

    @Test func belowIsSymmetric() {
        let alerts = [RateAlert(code: "USD", direction: .below, threshold: 5)]
        #expect(AlertEvaluator.evaluate(alerts, snapshot: snapshot(quote("USD", "5.1"))).fired.isEmpty)
        #expect(AlertEvaluator.evaluate(alerts, snapshot: snapshot(quote("USD", "4.99"))).fired.count == 1)
    }

    @Test func disabledNeverFires() {
        var a = RateAlert(code: "USD", direction: .above, threshold: 5)
        a.isEnabled = false
        let r = AlertEvaluator.evaluate([a], snapshot: snapshot(quote("USD", "9")))
        #expect(r.fired.isEmpty)
        #expect(r.updated == [a])
    }

    @Test func missingQuoteLeavesAlertUntouched() {
        let alerts = [RateAlert(code: "EUR", direction: .above, threshold: 5)]
        let r = AlertEvaluator.evaluate(alerts, snapshot: snapshot(quote("USD", "9")))
        #expect(r.fired.isEmpty)
        #expect(r.updated == alerts)
    }

    @Test func alertCodable() throws {
        let a = RateAlert(code: "BTC", direction: .below, threshold: Decimal(string: "400000")!)
        let back = try JSONDecoder().decode(RateAlert.self, from: JSONEncoder().encode(a))
        #expect(back == a)
    }
}

@Suite struct ClientURLTests {
    @Test func lastURLListsPairs() {
        #expect(AwesomeAPIClient.lastURL(codes: ["USD", "BTC"]).absoluteString == "https://economia.awesomeapi.com.br/json/last/USD-BRL,BTC-BRL")
    }
    @Test func dailyURL() {
        #expect(AwesomeAPIClient.dailyURL(code: "EUR", days: 30).absoluteString == "https://economia.awesomeapi.com.br/json/daily/EUR-BRL/30")
    }
}
