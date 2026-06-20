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

    @AppStorage("defaultQuality") var defaultQualityRaw = QualityPreference.balanced.rawValue {
        didSet { objectWillChange.send() }
    }

    var defaultQuality: QualityPreference {
        get { QualityPreference(rawValue: defaultQualityRaw) ?? .balanced }
        set { defaultQualityRaw = newValue.rawValue }
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
