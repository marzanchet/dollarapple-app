import AppKit
import DollarCore
import SwiftUI

struct PopoverView: View {
    let env: AppEnvironment
    @Environment(\.openSettings) private var openSettings
    @State private var selected = ""
    @State private var copied = false

    private var store: RatesStore { env.store }
    private var settings: DollarCore.Settings { env.settings }
    private var current: String { settings.isEnabled(selected) ? selected : settings.barCurrency }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if let q = store.quote(current) {
                SparklineView(points: store.history[current] ?? [])
                ConverterFields(code: current, rate: q.bid)
            }
            others
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 300)
        .task(id: current) { await store.loadHistory(current) }
        .onAppear { selected = settings.barCurrency }
    }

    // MARK: Header

    @ViewBuilder private var header: some View {
        switch store.state {
        case .loading:
            Text(L("popover.loading")).font(.callout).foregroundStyle(.secondary)
        case .failed(let code):
            Text(L("popover.failed", errorMessage(code))).font(.callout).foregroundStyle(.secondary)
        case .ok(let snap):
            mainQuote(snap, note: nil)
        case .stale(let snap, let code):
            mainQuote(snap, note: L("popover.stale", errorMessage(code)))
        }
    }

    @ViewBuilder private func mainQuote(_ snap: RatesSnapshot, note: String?) -> some View {
        if let q = snap[current] {
            VStack(alignment: .leading, spacing: 2) {
                Text(currencyName(q.code) + " (" + currencySymbol(q.code) + ")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(MoneyFormatter.brl(q.bid))
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                    Text(MoneyFormatter.percent(q.pctChange))
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(tone(q.pctChange))
                    Spacer()
                    if store.isRefreshing { ProgressView().controlSize(.small) }
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(MoneyFormatter.price(q.bid), forType: .string)
                        copied = true
                        Task { try? await Task.sleep(for: .seconds(1.5)); copied = false }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .help(L("popover.copy"))
                    .accessibilityLabel(copied ? L("popover.copied") : L("popover.copy"))
                }
                Text(updatedText(q.timestamp)).font(.caption).foregroundStyle(.secondary)
                if let note { Text(note).font(.caption).foregroundStyle(.orange) }
            }
        } else {
            Text(L("popover.loading")).font(.callout).foregroundStyle(.secondary)
        }
    }

    private func updatedText(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return L("popover.updatedAt", MoneyFormatter.time(date))
        }
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return L("popover.updatedOn", f.string(from: date))
    }

    // MARK: Other currencies

    @ViewBuilder private var others: some View {
        let rows = settings.enabledCurrencies.filter { $0 != current }
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("popover.otherCurrencies")).font(.caption2).foregroundStyle(.secondary)
                ForEach(rows, id: \.self) { code in
                    Button { selected = code } label: {
                        HStack(spacing: 8) {
                            Text(currencySymbol(code)).frame(width: 34, alignment: .leading).foregroundStyle(.secondary)
                            Text(currencyName(code)).lineLimit(1)
                            Spacer()
                            if let q = store.quote(code) {
                                Text(MoneyFormatter.brl(q.bid)).monospacedDigit()
                                Text(MoneyFormatter.percent(q.pctChange))
                                    .monospacedDigit()
                                    .foregroundStyle(tone(q.pctChange))
                                    .frame(width: 58, alignment: .trailing)
                            } else {
                                Text("…").foregroundStyle(.secondary)
                            }
                        }
                        .font(.callout)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(currencyName(code))
                }
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Button(L("popover.refresh")) { Task { await store.refresh() } }
                .disabled(store.isRefreshing)
            Spacer()
            Button {
                NSApplication.shared.activate()
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .help(L("popover.preferences"))
            .accessibilityLabel(L("popover.preferences"))
            .keyboardShortcut(",")
            Button(L("popover.quit")) { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }

    private func tone(_ pct: Decimal) -> Color {
        switch changeColor(pct) {
        case .up: .green
        case .down: .red
        case .flat: .secondary
        }
    }
}
