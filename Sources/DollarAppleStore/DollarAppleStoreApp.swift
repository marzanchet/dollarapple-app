import AppKit
import DollarAppleUI
import SwiftUI

/// Mac App Store build: sandboxed, the store handles updates.
@main
struct DollarAppleStoreApp: App {
    @State private var env: AppEnvironment

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        _env = State(initialValue: AppEnvironment(updater: NoUpdater()))
    }

    var body: some Scene {
        AppScenes(env: env)
    }
}
