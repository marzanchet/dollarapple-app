import DollarCore
import Foundation

/// The SwiftPM resource bundle. Resolved from the app's Resources folder first: the generated
/// `Bundle.module` accessor prefers the absolute build directory, which for a Finder-launched
/// app means a privacy prompt and a blocked main thread.
let resourceBundle: Bundle = {
    let name = "DollarApple_DollarAppleUI.bundle"
    if let url = Bundle.main.resourceURL?.appendingPathComponent(name),
       FileManager.default.fileExists(atPath: url.path),
       let bundle = Bundle(url: url) {
        return bundle
    }
    return Bundle.module
}()

/// Localized string from this module's catalog.
func L(_ key: String) -> String {
    resourceBundle.localizedString(forKey: key, value: nil, table: nil)
}

func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: L(key), locale: .current, arguments: args)
}

func currencyName(_ code: String) -> String {
    Currency.by(code: code).map { L($0.nameKey) } ?? code
}

func currencySymbol(_ code: String) -> String {
    Currency.by(code: code)?.symbol ?? code
}

/// Maps a `QuoteError.code` (or "network") to user-facing text.
func errorMessage(_ code: String) -> String {
    if code == "badPayload" { return L("error.badPayload") }
    if code.hasPrefix("http.") { return L("error.http", String(code.dropFirst(5))) }
    return L("error.network")
}

func changeColor(_ pct: Decimal) -> ChangeTone {
    pct > 0 ? .up : pct < 0 ? .down : .flat
}

enum ChangeTone { case up, down, flat }
