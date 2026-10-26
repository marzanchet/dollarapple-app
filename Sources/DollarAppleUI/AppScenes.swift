import DollarCore
import SwiftUI

/// The menu bar item plus the Preferences window. Shared by both executables.
public struct AppScenes: Scene {
    private let env: AppEnvironment

    public init(env: AppEnvironment) { self.env = env }

    public var body: some Scene {
        MenuBarExtra {
            PopoverView(env: env)
        } label: {
            MenuBarLabel(store: env.store, settings: env.settings)
        }
        .menuBarExtraStyle(.window)

        SwiftUI.Settings {
            PreferencesView(env: env)
        }
    }
}
