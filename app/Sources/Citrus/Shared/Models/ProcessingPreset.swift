import Foundation

enum ProcessingPreset: String, Codable, CaseIterable, Identifiable {
    case makeSmaller
    case bestQuality
    case webOptimized
    case emailFriendly
    case githubUpload

    var id: String { rawValue }

    var title: String {
        switch self {
        case .makeSmaller: "Make Smaller"
        case .bestQuality: "Best Quality"
        case .webOptimized: "Web Optimized"
        case .emailFriendly: "Email Friendly"
        case .githubUpload: "GitHub Upload"
        }
    }

    var subtitle: String {
        switch self {
        case .makeSmaller: "Reduce size without fuss"
        case .bestQuality: "Keep detail, trim waste"
        case .webOptimized: "Fast loading for websites"
        case .emailFriendly: "Small enough to send"
        case .githubUpload: "Ready for issue attachments"
        }
    }
}
