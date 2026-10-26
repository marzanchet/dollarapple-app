import DollarCore
import SwiftUI

struct MenuBarLabel: View {
    let store: RatesStore
    let settings: DollarCore.Settings

    var body: some View {
        Text(text)
            .monospacedDigit()
            .opacity(isStale ? 0.6 : 1)
    }

    private var isStale: Bool {
        if case .stale = store.state { return true }
        return false
    }

    private var text: String {
        switch store.state {
        case .loading: return "R$ …"
        case .failed: return "R$ --"
        case .ok, .stale:
            guard let q = store.quote(settings.barCurrency) else { return "R$ …" }
            let prefix = q.code == "USD" ? "" : currencySymbol(q.code) + " "
            var s = prefix + MoneyFormatter.brl(q.bid)
            if q.pctChange != 0 {
                s += " " + (q.pctChange > 0 ? "▲" : "▼")
                if settings.showChangeInBar { s += MoneyFormatter.percent(q.pctChange.magnitude) }
            } else if settings.showChangeInBar {
                s += " " + MoneyFormatter.percent(0)
            }
            return s
        }
    }
}
