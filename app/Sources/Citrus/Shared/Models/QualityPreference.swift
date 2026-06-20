import Foundation

enum QualityPreference: String, Codable, CaseIterable, Identifiable {
    case compact
    case balanced
    case high
    case maximum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: "Compact"
        case .balanced: "Balanced"
        case .high: "High"
        case .maximum: "Max"
        }
    }

    var detail: String {
        switch self {
        case .compact: "Smallest file. Good for quick sharing."
        case .balanced: "Recommended. Great quality, much smaller size."
        case .high: "Very sharp. Minimal quality loss."
        case .maximum: "Near-original quality. Largest file."
        }
    }

    /// Bits-per-pixel-per-frame target for H.264.
    var bitsPerPixel: Double {
        switch self {
        case .compact: 0.10
        case .balanced: 0.20
        case .high: 0.35
        case .maximum: 0.60
        }
    }
}
