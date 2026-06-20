import AVFoundation
import Foundation

/// Video container Citrus can export. Both wrap H.264 video + AAC audio.
enum OutputFormat: String, Codable, CaseIterable, Identifiable {
    case keepOriginal
    case mp4
    case mov

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepOriginal: "Keep Format"
        case .mp4: "MP4"
        case .mov: "MOV"
        }
    }

    static let videoFormats: [OutputFormat] = [.keepOriginal, .mp4, .mov]

    /// Concrete container extension to write, resolving `keepOriginal`.
    func resolvedExtension(sourceExtension: String) -> String {
        switch self {
        case .mp4: "mp4"
        case .mov: "mov"
        case .keepOriginal: sourceExtension.lowercased() == "mov" ? "mov" : "mp4"
        }
    }

    func resolvedFileType(sourceExtension: String) -> AVFileType {
        resolvedExtension(sourceExtension: sourceExtension) == "mov" ? .mov : .mp4
    }
}
