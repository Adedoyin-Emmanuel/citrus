import SwiftUI

@main
struct CitrusApp: App {
    @NSApplicationDelegateAdaptor(CitrusAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.settingsStore)
        }
    }
}
