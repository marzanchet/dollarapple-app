import Foundation

public struct RateAlert: Identifiable, Codable, Equatable, Sendable {
    public enum Direction: String, Codable, Sendable, CaseIterable {
        case above, below
    }

    public var id: UUID
    public var code: String
    public var direction: Direction
    public var threshold: Decimal
    public var isEnabled: Bool
    /// Armed means the next crossing fires. Disarmed after firing until the rate crosses back.
    public var isArmed: Bool

    public init(id: UUID = UUID(), code: String, direction: Direction, threshold: Decimal,
                isEnabled: Bool = true, isArmed: Bool = true) {
        self.id = id
        self.code = code
        self.direction = direction
        self.threshold = threshold
        self.isEnabled = isEnabled
        self.isArmed = isArmed
    }
}

public enum AlertEvaluator {
    public static func evaluate(_ alerts: [RateAlert], snapshot: RatesSnapshot) -> (updated: [RateAlert], fired: [RateAlert]) {
        var updated = alerts
        var fired: [RateAlert] = []
        for i in updated.indices {
            var alert = updated[i]
            guard alert.isEnabled, let quote = snapshot[alert.code] else { continue }
            let crossed = alert.direction == .above ? quote.bid >= alert.threshold : quote.bid <= alert.threshold
            if crossed && alert.isArmed {
                alert.isArmed = false
                fired.append(alert)
            } else if !crossed && !alert.isArmed {
                alert.isArmed = true
            }
            updated[i] = alert
        }
        return (updated, fired)
    }
}
