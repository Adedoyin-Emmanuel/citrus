import Foundation

/// Real processing engine. Citrus is video-only: every job is compressed/
/// transcoded by the video optimizer. Cleans up partial output on failure.
struct MediaOptimizer: MediaProcessing {
    func process(job: MediaJob, to destination: URL) -> AsyncThrowingStream<ProcessingUpdate, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await VideoOptimizer().optimize(job: job, to: destination) { value in
                        continuation.yield(ProcessingUpdate(progress: max(0.02, value), estimatedSecondsRemaining: nil))
                    }
                    continuation.finish()
                } catch is CancellationError {
                    try? FileManager.default.removeItem(at: destination)
                    continuation.finish(throwing: ProcessingError.cancelled)
                } catch {
                    try? FileManager.default.removeItem(at: destination)
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }
}
