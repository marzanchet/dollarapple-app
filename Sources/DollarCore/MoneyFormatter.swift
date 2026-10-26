import Foundation

public enum MoneyFormatter {
    private static let posix = Locale(identifier: "en_US_POSIX")

    private static func formatter(locale: Locale, minFraction: Int, maxFraction: Int) -> NumberFormatter {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.minimumFractionDigits = minFraction
        f.maximumFractionDigits = maxFraction
        f.usesGroupingSeparator = true
        f.roundingMode = .halfUp
        return f
    }

    /// Price display: no cents from 10.000 up, 2 decimals from 1 up, 4 decimals below 1.
    public static func price(_ value: Decimal, locale: Locale = .current) -> String {
        let digits: Int = value.magnitude >= 10_000 ? 0 : value.magnitude >= 1 ? 2 : 4
        return formatter(locale: locale, minFraction: digits, maxFraction: digits)
            .string(from: value as NSDecimalNumber) ?? "0"
    }

    /// Editable amount: at least 2 decimals, up to 8 (so a BTC amount survives).
    public static func amount(_ value: Decimal, locale: Locale = .current) -> String {
        formatter(locale: locale, minFraction: 2, maxFraction: 8)
            .string(from: value as NSDecimalNumber) ?? "0"
    }

    public static func brl(_ value: Decimal, locale: Locale = .current) -> String {
        "R$ " + price(value, locale: locale)
    }

    /// Accepts the locale's separators and the other locale's too when unambiguous.
    public static func parse(_ text: String, locale: Locale = .current) -> Decimal? {
        var s = text.filter { $0.isNumber || $0 == "," || $0 == "." || $0 == "-" }
        guard s.contains(where: \.isNumber) else { return nil }
        let decimalSep = Character(locale.decimalSeparator ?? ".")
        let comma = s.lastIndex(of: ","), dot = s.lastIndex(of: ".")
        switch (comma, dot) {
        case let (c?, d?):
            // Both present: the later one is the decimal separator.
            if c > d { s.removeAll { $0 == "." }; s = s.replacingOccurrences(of: ",", with: ".") }
            else { s.removeAll { $0 == "," } }
        case (nil, nil):
            break
        default:
            let sep: Character = comma != nil ? "," : "."
            let count = s.filter { $0 == sep }.count
            let trailing = s.distance(from: s.lastIndex(of: sep)!, to: s.endIndex) - 1
            let isGrouping = count > 1 || (sep != decimalSep && trailing == 3)
            if isGrouping { s.removeAll { $0 == sep } }
            else if sep == "," { s = s.replacingOccurrences(of: ",", with: ".") }
        }
        return Decimal(string: s, locale: posix)
    }

    public static func percent(_ value: Decimal, locale: Locale = .current) -> String {
        let body = formatter(locale: locale, minFraction: 2, maxFraction: 2)
            .string(from: value.magnitude as NSDecimalNumber) ?? "0"
        if value > 0 { return "+" + body + "%" }
        if value < 0 { return "-" + body + "%" }
        return body + "%"
    }

    public static func time(_ date: Date, timeZone: TimeZone = .current, locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = timeZone
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
