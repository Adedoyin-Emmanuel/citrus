import Foundation

enum SupportedMedia {
    static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "webp", "heic", "avif"]
    static let videoExtensions: Set<String> = ["mp4", "mov", "mkv", "avi", "webm"]

    static func kind(for url: URL) -> MediaKind {
        let ext = url.pathExtension.lowercased()
        if imageExtensions.contains(ext) { return .image }
        if videoExtensions.contains(ext) { return .video }
        return .unsupported
    }

    static func isSupported(_ url: URL) -> Bool {
        kind(for: url) != .unsupported
    }
}
