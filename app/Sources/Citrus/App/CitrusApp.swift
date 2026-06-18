import SwiftUI

@main
struct CitrusApp: App {
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var queueViewModel: QueueViewModel

    init() {
        let settings = SettingsStore()
        let notificationCenter = CitrusNotificationCenter()
        let processor = MockMediaProcessor()
        _settingsStore = StateObject(wrappedValue: settings)
        _queueViewModel = StateObject(
            wrappedValue: QueueViewModel(
                processor: processor,
                notificationCenter: notificationCenter,
                settingsStore: settings
            )
        )
    }

    var body: some Scene {
        MenuBarExtra {
            DashboardView()
                .environmentObject(queueViewModel)
                .environmentObject(settingsStore)
        } label: {
            Image(systemName: "circle.hexagongrid.fill")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(settingsStore)
        }
    }
}
