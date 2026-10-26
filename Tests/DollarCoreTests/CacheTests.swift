import Foundation
import Testing
@testable import DollarCore

@Suite struct CacheTests {
    @Test func emptyOnFirstRun() {
        #expect(Cache<RatesSnapshot>(defaults: freshDefaults(), key: "snap").load() == nil)
    }

    @Test func roundTripSnapshot() {
        let cache = Cache<RatesSnapshot>(defaults: freshDefaults(), key: "snap")
        let snap = snapshot(quote("USD", "5.1259", pct: "0.01"), quote("BTC", "409853"))
        cache.save(snap)
        #expect(cache.load() == snap)
    }

    @Test func roundTripHistory() {
        let cache = Cache<[HistoryPoint]>(defaults: freshDefaults(), key: "hist.USD")
        let pts = [HistoryPoint(date: Date(timeIntervalSince1970: 1), bid: 5), HistoryPoint(date: Date(timeIntervalSince1970: 2), bid: 6)]
        cache.save(pts)
        #expect(cache.load() == pts)
    }

    @Test func keysAreIndependentAndClearWorks() {
        let d = freshDefaults()
        let a = Cache<Int>(defaults: d, key: "a"), b = Cache<Int>(defaults: d, key: "b")
        a.save(1); b.save(2)
        #expect(a.load() == 1 && b.load() == 2)
        a.clear()
        #expect(a.load() == nil && b.load() == 2)
    }

    @Test func corruptDataReturnsNil() {
        let d = freshDefaults()
        d.set(Data("junk".utf8), forKey: "snap")
        #expect(Cache<RatesSnapshot>(defaults: d, key: "snap").load() == nil)
    }
}
