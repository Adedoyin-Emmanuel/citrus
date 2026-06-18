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

            Section("Processing") {
                Picker("Default image preset", selection: $settings.defaultImagePreset) {
                    ForEach(ProcessingPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }

                Picker("Default video preset", selection: $settings.defaultVideoPreset) {
                    ForEach(ProcessingPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 300)
    }
}
