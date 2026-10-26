import Foundation

/// Self-update hook. The direct build injects Sparkle; the App Store build injects `NoUpdater`.
@MainActor
public protocol Updater: AnyObject {
    var isAvailable: Bool { get }
    func checkForUpdates()
}

@MainActor
public final class NoUpdater: Updater {
    public init() {}
    public var isAvailable: Bool { false }
    public func checkForUpdates() {}
}
