import Foundation
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("launchAtLogin") var launchAtLogin = false {
        didSet { objectWillChange.send() }
    }

    @AppStorage("notificationsEnabled") var notificationsEnabled = true {
        didSet { objectWillChange.send() }
    }

    @AppStorage("outputLocation") var outputLocation = OutputLocation.downloads.rawValue {
        didSet { objectWillChange.send() }
    }

    @AppStorage("defaultImagePreset") var defaultImagePresetRaw = ProcessingPreset.makeSmaller.rawValue {
        didSet { objectWillChange.send() }
    }

    @AppStorage("defaultVideoPreset") var defaultVideoPresetRaw = ProcessingPreset.webOptimized.rawValue {
        didSet { objectWillChange.send() }
    }

    var defaultImagePreset: ProcessingPreset {
        get { ProcessingPreset(rawValue: defaultImagePresetRaw) ?? .makeSmaller }
        set { defaultImagePresetRaw = newValue.rawValue }
    }

    var defaultVideoPreset: ProcessingPreset {
        get { ProcessingPreset(rawValue: defaultVideoPresetRaw) ?? .webOptimized }
        set { defaultVideoPresetRaw = newValue.rawValue }
    }

    var outputLocationChoice: OutputLocation {
        get { OutputLocation(rawValue: outputLocation) ?? .downloads }
        set { outputLocation = newValue.rawValue }
    }
}

enum OutputLocation: String, CaseIterable, Identifiable {
    case sourceFolder
    case downloads
    case askEveryTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sourceFolder: "Same as Original"
        case .downloads: "Downloads"
        case .askEveryTime: "Ask Every Time"
        }
    }
}
