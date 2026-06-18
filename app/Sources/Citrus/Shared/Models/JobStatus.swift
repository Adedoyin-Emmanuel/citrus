import Foundation

enum JobStatus: String, Codable, CaseIterable, Identifiable {
    case waiting
    case processing
    case completed
    case failed
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .waiting: "Waiting"
        case .processing: "Processing"
        case .completed: "Completed"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }
}
