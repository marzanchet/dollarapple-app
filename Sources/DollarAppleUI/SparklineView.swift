import Charts
import DollarCore
import SwiftUI

struct SparklineView: View {
    let points: [HistoryPoint]

    var body: some View {
        if points.count >= 2, let first = points.first, let last = points.last {
            let tone = changeColor(last.bid - first.bid)
            let color: Color = tone == .up ? .green : tone == .down ? .red : .secondary
            let values = points.map { NSDecimalNumber(decimal: $0.bid).doubleValue }
            let lo = values.min() ?? 0, hi = values.max() ?? 1
            let pad = max((hi - lo) * 0.15, hi * 0.002)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(L("popover.chart30d"))
                    Spacer()
                    Text(MoneyFormatter.price(points.map(\.bid).min() ?? 0) + " – " + MoneyFormatter.price(points.map(\.bid).max() ?? 0))
                        .monospacedDigit()
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                Chart(Array(zip(points, values)), id: \.0.date) { point, value in
                    AreaMark(x: .value("date", point.date), y: .value("bid", value))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(LinearGradient(colors: [color.opacity(0.28), .clear], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("date", point.date), y: .value("bid", value))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: (lo - pad)...(hi + pad))
                .frame(height: 52)
                .accessibilityLabel(L("popover.chart30d"))
            }
        } else {
            Text(L("popover.chartUnavailable"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
