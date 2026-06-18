import Foundation

struct MediaJob: Identifiable, Equatable {
    let id: UUID
    let fileURL: URL
    let fileName: String
    let fileSize: Int64
    let mediaKind: MediaKind
    let preset: ProcessingPreset
    var progress: Double
    var status: JobStatus
    var estimatedSecondsRemaining: Int?
    var errorMessage: String?

    init(
        id: UUID = UUID(),
        fileURL: URL,
        fileSize: Int64,
        mediaKind: MediaKind,
        preset: ProcessingPreset,
        progress: Double = 0,
        status: JobStatus = .waiting,
        estimatedSecondsRemaining: Int? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.fileURL = fileURL
        self.fileName = fileURL.lastPathComponent
        self.fileSize = fileSize
        self.mediaKind = mediaKind
        self.preset = preset
        self.progress = progress
        self.status = status
        self.estimatedSecondsRemaining = estimatedSecondsRemaining
        self.errorMessage = errorMessage
    }
}
