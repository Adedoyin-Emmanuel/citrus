import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Toggle("Notify when jobs finish", isOn: $settings.notificationsEnabled)

                Picker("Output location", selection: $settings.outputLocationChoice) {
                    ForEach(OutputLocation.allCases) { location in
                        Text(location.title).tag(location)
                    }
                }
            }

            Section("Compression") {
                Picker("Default level", selection: $settings.defaultQuality) {
                    ForEach(QualityPreference.allCases) { quality in
                        Text(quality.title).tag(quality)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 300)
    }
}
