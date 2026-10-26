import AppKit
import DollarCore
import SwiftUI
import UserNotifications

public struct PreferencesView: View {
    let env: AppEnvironment

    public init(env: AppEnvironment) { self.env = env }

    public var body: some View {
        TabView {
            GeneralTab(settings: env.settings)
                .tabItem { Label(L("prefs.general"), systemImage: "gearshape") }
            CurrenciesTab(settings: env.settings)
                .tabItem { Label(L("prefs.currencies"), systemImage: "coloncurrencysign.circle") }
            AlertsTab(settings: env.settings, store: env.store, notifier: env.notifier)
                .tabItem { Label(L("prefs.alerts"), systemImage: "bell") }
            AboutTab(updater: env.updater)
                .tabItem { Label(L("prefs.about"), systemImage: "info.circle") }
        }
        .frame(width: 460, height: 340)
        .navigationTitle(L("prefs.title"))
    }
}

// MARK: - Geral

private struct GeneralTab: View {
    @Bindable var settings: DollarCore.Settings
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            Picker(L("prefs.barCurrency"), selection: $settings.barCurrency) {
                ForEach(settings.enabledCurrencies, id: \.self) { code in
                    Text(currencyName(code) + " (" + currencySymbol(code) + ")").tag(code)
                }
            }
            Toggle(L("prefs.showChange"), isOn: $settings.showChangeInBar)
            Picker(L("prefs.refreshInterval"), selection: $settings.refreshInterval) {
                ForEach(DollarCore.Settings.refreshIntervals, id: \.self) { seconds in
                    Text(L("prefs.interval.\(seconds)")).tag(seconds)
                }
            }
            Section {
                Toggle(L("prefs.launchAtLogin"), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in
                        if !LaunchAtLogin.set(on) { launchAtLogin = LaunchAtLogin.isEnabled }
                    }
            } footer: {
                Text(L("prefs.launchAtLoginHint")).font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Moedas

private struct CurrenciesTab: View {
    let settings: DollarCore.Settings

    var body: some View {
        Form {
            Section {
                ForEach(Currency.all) { currency in
                    Toggle(isOn: Binding(
                        get: { settings.isEnabled(currency.code) },
                        set: { settings.setEnabled(currency.code, $0) }
                    )) {
                        HStack {
                            Text(currency.symbol).frame(width: 44, alignment: .leading).foregroundStyle(.secondary)
                            Text(L(currency.nameKey))
                            Spacer()
                            Text(currency.code).foregroundStyle(.secondary).monospaced()
                        }
                    }
                }
            } footer: {
                Text(L("prefs.currenciesHint")).font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Alertas

private struct AlertsTab: View {
    @Bindable var settings: DollarCore.Settings
    let store: RatesStore
    let notifier: Notifier
    @State private var denied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if settings.alerts.isEmpty {
                Spacer()
                Text(L("prefs.alerts.empty"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 30)
                Spacer()
            } else {
                List {
                    ForEach($settings.alerts) { $alert in
                        AlertRow(alert: $alert) {
                            settings.alerts.removeAll { $0.id == alert.id }
                        }
                    }
                }
            }
            HStack {
                Button(L("prefs.alerts.add")) { add() }
                Spacer()
                Text(denied ? L("prefs.alerts.notifyDenied") : L("prefs.alerts.notifyHint"))
                    .font(.caption)
                    .foregroundStyle(denied ? .orange : .secondary)
                    .lineLimit(2)
            }
            .padding([.horizontal, .bottom], 12)
        }
        .task { await checkAuthorization() }
    }

    private func add() {
        let code = settings.barCurrency
        let bid = store.quote(code)?.bid ?? 0
        settings.alerts.append(RateAlert(code: code, direction: .above, threshold: bid))
        notifier.requestAuthorization()
        Task { await checkAuthorization() }
    }

    private func checkAuthorization() async {
        denied = await notifier.authorizationStatus() == .denied
    }
}

private struct AlertRow: View {
    @Binding var alert: RateAlert
    let remove: () -> Void
    @State private var thresholdText = ""

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: $alert.isEnabled).labelsHidden()
            Picker("", selection: $alert.code) {
                ForEach(Currency.all) { Text($0.code).tag($0.code) }
            }
            .labelsHidden()
            .frame(width: 80)
            Picker("", selection: $alert.direction) {
                Text(L("prefs.alerts.above")).tag(RateAlert.Direction.above)
                Text(L("prefs.alerts.below")).tag(RateAlert.Direction.below)
            }
            .labelsHidden()
            .frame(width: 110)
            TextField(L("prefs.alerts.threshold"), text: $thresholdText)
                .textFieldStyle(.roundedBorder)
                .monospacedDigit()
                .frame(width: 110)
                .onSubmit(commit)
            Spacer()
            Button(role: .destructive, action: remove) { Image(systemName: "trash") }
                .buttonStyle(.borderless)
                .help(L("prefs.alerts.remove"))
        }
        .onAppear { thresholdText = MoneyFormatter.amount(alert.threshold) }
        .onChange(of: thresholdText) { _, _ in commit() }
        .onChange(of: alert.code) { _, _ in alert.isArmed = true }
        .onChange(of: alert.direction) { _, _ in alert.isArmed = true }
    }

    private func commit() {
        guard let value = MoneyFormatter.parse(thresholdText), value > 0, value != alert.threshold else { return }
        alert.threshold = value
        alert.isArmed = true
    }
}

// MARK: - Sobre

private struct AboutTab: View {
    let updater: any Updater

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
            Text("DollarApple").font(.title2.weight(.semibold))
            Text(L("about.version", version)).font(.caption).foregroundStyle(.secondary)
            Text(L("about.tagline")).multilineTextAlignment(.center).padding(.horizontal, 30)
            Text(L("about.data")).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 30)
            HStack(spacing: 16) {
                Link(L("about.github"), destination: URL(string: "https://github.com/marzanchet/dollarapple")!)
                if updater.isAvailable {
                    Button(L("about.checkUpdates")) { updater.checkForUpdates() }
                }
            }
        }
        .padding()
    }
}
