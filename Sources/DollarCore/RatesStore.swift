import Foundation
import Observation

/// Owns the latest rates, per-currency history and the refresh loop.
@MainActor @Observable
public final class RatesStore {
    public enum State: Equatable {
        case loading
        case ok(RatesSnapshot)
        case stale(RatesSnapshot, String)
        case failed(String)
    }

    public static let snapshotKey = "rates.snapshot"
    public static let historyDays = 30
    public static let historyMaxAge: TimeInterval = 3600

    private struct HistoryEntry: Codable {
        let points: [HistoryPoint]
        let fetchedAt: Date
    }

    public private(set) var state: State
    public private(set) var isRefreshing = false
    public private(set) var history: [String: [HistoryPoint]] = [:]
    /// Called on the main actor with the alerts that just crossed their threshold.
    public var onFired: (([RateAlert]) -> Void)?

    private let client: any RatesClient
    private let settings: Settings
    private let defaults: UserDefaults
    private let snapshotCache: Cache<RatesSnapshot>
    private var historyFetchedAt: [String: Date] = [:]
    private var loop: Task<Void, Never>?
    private var observing = false

    public init(client: any RatesClient, settings: Settings, defaults: UserDefaults = .standard) {
        self.client = client
        self.settings = settings
        self.defaults = defaults
        self.snapshotCache = Cache(defaults: defaults, key: Self.snapshotKey)
        self.state = snapshotCache.load().map(State.ok) ?? .loading
    }

    public var snapshot: RatesSnapshot? {
        switch state {
        case .ok(let s), .stale(let s, _): s
        case .loading, .failed: nil
        }
    }

    public func quote(_ code: String) -> Quote? { snapshot?[code] }

    // MARK: Refresh loop

    public func start() {
        stop()
        observeSettings()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                guard let seconds = self?.settings.refreshInterval else { return }
                try? await Task.sleep(for: .seconds(seconds))
            }
        }
    }

    public func stop() {
        loop?.cancel()
        loop = nil
        observing = false
    }

    /// Restart the loop (and refresh at once) whenever the enabled currencies or the interval change.
    private func observeSettings() {
        observing = true
        withObservationTracking {
            _ = settings.enabledCurrencies
            _ = settings.refreshInterval
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.observing else { return }
                self.start()
            }
        }
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let fresh = try await client.fetchLast(codes: settings.enabledCurrencies)
            snapshotCache.save(fresh)
            state = .ok(fresh)
            evaluateAlerts(fresh)
        } catch {
            let code = (error as? QuoteError)?.code ?? "network"
            if let previous = snapshot { state = .stale(previous, code) }
            else { state = .failed(code) }
        }
    }

    private func evaluateAlerts(_ snapshot: RatesSnapshot) {
        let result = AlertEvaluator.evaluate(settings.alerts, snapshot: snapshot)
        if result.updated != settings.alerts { settings.alerts = result.updated }
        if !result.fired.isEmpty { onFired?(result.fired) }
    }

    // MARK: History

    public func loadHistory(_ code: String, force: Bool = false) async {
        let cache = Cache<HistoryEntry>(defaults: defaults, key: "history.\(code)")
        if history[code] == nil, let entry = cache.load() {
            history[code] = entry.points
            historyFetchedAt[code] = entry.fetchedAt
        }
        if !force, let at = historyFetchedAt[code], Date().timeIntervalSince(at) < Self.historyMaxAge {
            return
        }
        do {
            let points = try await client.fetchDaily(code: code, days: Self.historyDays)
            let now = Date()
            history[code] = points
            historyFetchedAt[code] = now
            cache.save(HistoryEntry(points: points, fetchedAt: now))
        } catch {
            // Keep whatever we had; the sparkline just does not update.
        }
    }
}
