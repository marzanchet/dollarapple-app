import AppKit
import DollarAppleUI
import Sparkle
import SwiftUI

/// Direct-distribution build: self-updates through Sparkle.
@MainActor
final class SparkleUpdater: Updater {
    private let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    var isAvailable: Bool { true }
    func checkForUpdates() { controller.checkForUpdates(nil) }
}

@main
struct DollarAppleApp: App {
    @State private var env: AppEnvironment

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        _env = State(initialValue: AppEnvironment(updater: SparkleUpdater()))
    }

    var body: some Scene {
        AppScenes(env: env)
    }
}
