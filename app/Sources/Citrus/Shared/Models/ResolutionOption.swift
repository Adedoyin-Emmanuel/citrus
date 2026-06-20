import Foundation

/// Output resolution cap for a video. Scales by the smaller dimension so it works
/// for both landscape and portrait footage, and never upscales.
enum ResolutionOption: String, Codable, CaseIterable, Identifiable {
    case original
    case p2160
    case p1080
    case p720
    case p480
    case p360

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original: "Original"
        case .p2160: "4K"
        case .p1080: "1080p"
        case .p720: "720p"
        case .p480: "480p"
        case .p360: "360p"
        }
    }

    /// Target for the smaller edge in pixels; `nil` keeps the source resolution.
    var pixels: Int? {
        switch self {
        case .original: nil
        case .p2160: 2160
        case .p1080: 1080
        case .p720: 720
        case .p480: 480
        case .p360: 360
        }
    }
}
