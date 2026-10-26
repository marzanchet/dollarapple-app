import DollarCore
import SwiftUI

/// Two text fields: foreign amount and BRL amount, each recomputing the other while focused.
struct ConverterFields: View {
    let code: String
    let rate: Decimal

    private enum Field { case foreign, brl }
    @FocusState private var focus: Field?
    @State private var foreignText = ""
    @State private var brlText = ""

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            field(currencyName(code) + " (" + currencySymbol(code) + ")", text: $foreignText, field: .foreign)
            Image(systemName: "arrow.left.arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 22)
            field(L("popover.brl"), text: $brlText, field: .brl)
        }
        .onAppear(perform: reset)
        .onChange(of: code) { _, _ in reset() }
        .onChange(of: rate) { _, _ in if focus != .brl { recomputeBRL() } else { recomputeForeign() } }
        .onChange(of: foreignText) { _, _ in if focus == .foreign { recomputeBRL() } }
        .onChange(of: brlText) { _, _ in if focus == .brl { recomputeForeign() } }
    }

    private func field(_ title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            TextField("0", text: text)
                .textFieldStyle(.roundedBorder)
                .font(.body.monospacedDigit())
                .focused($focus, equals: field)
                .accessibilityLabel(title)
        }
    }

    private func reset() {
        foreignText = MoneyFormatter.amount(1)
        recomputeBRL()
    }

    private func recomputeBRL() {
        guard let amount = MoneyFormatter.parse(foreignText) else { return }
        brlText = MoneyFormatter.amount(Converter.toBRL(amount: amount, rate: rate))
    }

    private func recomputeForeign() {
        guard let brl = MoneyFormatter.parse(brlText), let amount = Converter.fromBRL(brl: brl, rate: rate) else { return }
        foreignText = MoneyFormatter.amount(amount)
    }
}
