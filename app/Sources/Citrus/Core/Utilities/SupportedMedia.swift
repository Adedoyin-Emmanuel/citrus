import Foundation

enum SupportedMedia {
    static let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "mkv", "avi", "webm"]

    static func isSupported(_ url: URL) -> Bool {
        videoExtensions.contains(url.pathExtension.lowercased())
    }
}
