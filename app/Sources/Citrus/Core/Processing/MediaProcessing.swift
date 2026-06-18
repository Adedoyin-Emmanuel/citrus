import Foundation

struct ProcessingUpdate: Sendable {
    let progress: Double
    let estimatedSecondsRemaining: Int?
}

protocol MediaProcessing: Sendable {
    func process(job: MediaJob) -> AsyncThrowingStream<ProcessingUpdate, Error>
}

enum ProcessingError: LocalizedError {
    case cancelled
    case unsupportedFile

    var errorDescription: String? {
        switch self {
        case .cancelled: "The job was cancelled."
        case .unsupportedFile: "This file type is not supported yet."
        }
    }
}
