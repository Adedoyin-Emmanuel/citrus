import Foundation

struct ProcessingUpdate: Sendable {
    let progress: Double
    let estimatedSecondsRemaining: Int?
}

protocol MediaProcessing: Sendable {
    func process(job: MediaJob, to destination: URL) -> AsyncThrowingStream<ProcessingUpdate, Error>
}

enum ProcessingError: LocalizedError {
    case cancelled
    case unsupportedFile
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .cancelled: "The job was cancelled."
        case .unsupportedFile: "This file type is not supported yet."
        case .exportFailed: "Citrus couldn't write the optimized file."
        }
    }
}
