import Foundation

public enum Converter {
    /// Foreign amount to BRL, rounded to cents.
    public static func toBRL(amount: Decimal, rate: Decimal) -> Decimal { round(amount * rate, scale: 2) }

    /// BRL to foreign amount. Cents normally; 8 decimals when the result is below one cent (BTC).
    public static func fromBRL(brl: Decimal, rate: Decimal) -> Decimal? {
        guard rate > 0 else { return nil }
        let raw = brl / rate
        let cents = round(raw, scale: 2)
        return (cents == 0 && raw != 0) ? round(raw, scale: 8) : cents
    }

    static func round(_ value: Decimal, scale: Int) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, scale, .plain)
        return output
    }
}
