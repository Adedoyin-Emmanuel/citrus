import Foundation

enum MediaKind: String, Codable, CaseIterable, Identifiable {
    case image
    case video
    case unsupported

    var id: String { rawValue }
}
