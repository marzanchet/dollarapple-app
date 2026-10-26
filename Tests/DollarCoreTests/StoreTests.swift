import Foundation
import Testing
@testable import DollarCore

final class MockClient: RatesClient, @unchecked Sendable {
    var last: Result<RatesSnapshot, Error>
    var daily: Result<[HistoryPoint], Error> = .success([HistoryPoint(date: Date(timeIntervalSince1970: 1), bid: 5)])
    var lastCalls: [[String]] = []
    var dailyCalls: [String] = []
    init(_ last: Result<RatesSnapshot, Error>) { self.last = last }
    func fetchLast(codes: [String]) async throws -> RatesSnapshot { lastCalls.append(codes); return try last.get() }
    func fetchDaily(code: String, days: Int) async throws -> [HistoryPoint] { dailyCalls.append(code); return try daily.get() }
}

@MainActor @Suite struct StoreTests {
    let s1 = snapshot(quote("USD", "5.10"), quote("EUR", "5.9"), quote("BTC", "400000"))
    let s2 = snapshot(quote("USD", "5.20"), quote("EUR", "6.0"), quote("BTC", "410000"))

    func make(_ result: Result<RatesSnapshot, Error>, defaults: UserDefaults = freshDefaults()) -> (RatesStore, MockClient, Settings) {
        let client = MockClient(result)
        let settings = Settings(defaults: defaults)
        let store = RatesStore(client: client, settings: settings, defaults: defaults)
        return (store, client, settings)
    }

    func waitUntil(_ cond: @escaping @MainActor () -> Bool) async throws {
        for _ in 0..<100 where !cond() { try await Task.sleep(for: .milliseconds(10)) }
    }

    @Test func startsLoadingWithoutCache() {
        let (store, _, _) = make(.success(s1))
        #expect(store.state == .loading)
        #expect(store.snapshot == nil)
    }

    @Test func startsOkFromCache() {
        let d = freshDefaults()
        Cache<RatesSnapshot>(defaults: d, key: RatesStore.snapshotKey).save(s1)
        let (store, _, _) = make(.success(s2), defaults: d)
        #expect(store.state == .ok(s1))
    }

    @Test func refreshFetchesOnlyEnabledCodes() async {
        let (store, client, settings) = make(.success(s2))
        settings.setEnabled("EUR", false)
        await store.refresh()
        #expect(client.lastCalls == [["USD", "BTC"]])
        #expect(store.state == .ok(s2))
    }

    @Test func refreshFailureWithCacheGoesStale() async {
        let d = freshDefaults()
        Cache<RatesSnapshot>(defaults: d, key: RatesStore.snapshotKey).save(s1)
        let (store, _, _) = make(.failure(QuoteError.http(500)), defaults: d)
        await store.refresh()
        #expect(store.state == .stale(s1, "http.500"))
        #expect(store.quote("USD")?.bid == Decimal(string: "5.10"))
    }

    @Test func refreshFailureWithoutCacheFails() async {
        let (store, _, _) = make(.failure(QuoteError.badPayload))
        await store.refresh()
        #expect(store.state == .failed("badPayload"))
    }

    @Test func recoversFromStale() async {
        let d = freshDefaults()
        Cache<RatesSnapshot>(defaults: d, key: RatesStore.snapshotKey).save(s1)
        let (store, client, _) = make(.failure(QuoteError.http(500)), defaults: d)
        await store.refresh()
        client.last = .success(s2)
        await store.refresh()
        #expect(store.state == .ok(s2))
    }

    @Test func alertsEvaluatedAndPersistedAfterRefresh() async {
        let (store, _, settings) = make(.success(s2))
        settings.alerts = [RateAlert(code: "USD", direction: .above, threshold: 5), RateAlert(code: "EUR", direction: .above, threshold: 9)]
        var fired: [RateAlert] = []
        store.onFired = { fired = $0 }
        await store.refresh()
        #expect(fired.map(\.code) == ["USD"])
        #expect(settings.alerts[0].isArmed == false)
        #expect(settings.alerts[1].isArmed == true)
    }

    @Test func historyCachedForAnHour() async {
        let (store, client, _) = make(.success(s1))
        await store.loadHistory("USD")
        await store.loadHistory("USD")
        #expect(client.dailyCalls == ["USD"])
        #expect(store.history["USD"]?.count == 1)
        await store.loadHistory("USD", force: true)
        #expect(client.dailyCalls == ["USD", "USD"])
    }

    @Test func historySurvivesRestart() async {
        let d = freshDefaults()
        let (a, _, _) = make(.success(s1), defaults: d)
        await a.loadHistory("BTC")
        let (b, clientB, _) = make(.success(s1), defaults: d)
        await b.loadHistory("BTC")
        #expect(clientB.dailyCalls.isEmpty)
        #expect(b.history["BTC"]?.count == 1)
    }

    @Test func historyFailureKeepsOldPoints() async {
        let (store, client, _) = make(.success(s1))
        await store.loadHistory("USD")
        client.daily = .failure(QuoteError.http(500))
        await store.loadHistory("USD", force: true)
        #expect(store.history["USD"]?.count == 1)
    }

    @Test func startFetchesImmediatelyAndReactsToSettings() async throws {
        let (store, client, settings) = make(.success(s1))
        store.start()
        try await waitUntil { client.lastCalls.count == 1 }
        #expect(store.state == .ok(s1))
        settings.setEnabled("GBP", true)
        try await waitUntil { client.lastCalls.count == 2 }
        store.stop()
        #expect(client.lastCalls.last == ["USD", "EUR", "GBP", "BTC"])
    }
}
