import Foundation

struct MockMediaProcessor: MediaProcessing {
    func process(job: MediaJob) -> AsyncThrowingStream<ProcessingUpdate, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for step in 1...20 {
                        try Task.checkCancellation()
                        try await Task.sleep(for: .milliseconds(140))
                        let progress = Double(step) / 20
                        continuation.yield(
                            ProcessingUpdate(
                                progress: progress,
                                estimatedSecondsRemaining: step == 20 ? nil : max(1, 20 - step) / 3
                            )
                        )
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: ProcessingError.cancelled)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
