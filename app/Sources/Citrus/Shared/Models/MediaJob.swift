import Foundation

struct MediaJob: Identifiable, Equatable {
    let id: UUID
    let fileURL: URL
    let fileName: String
    let fileSize: Int64
    var quality: QualityPreference
    var outputFormat: OutputFormat
    var resolution: ResolutionOption
    var progress: Double
    var status: JobStatus
    var estimatedSecondsRemaining: Int?
    var outputURL: URL?
    var outputFileSize: Int64?
    var errorMessage: String?

    init(
        id: UUID = UUID(),
        fileURL: URL,
        fileSize: Int64,
        quality: QualityPreference,
        outputFormat: OutputFormat = .keepOriginal,
        resolution: ResolutionOption = .original,
        progress: Double = 0,
        status: JobStatus = .waiting,
        estimatedSecondsRemaining: Int? = nil,
        outputURL: URL? = nil,
        outputFileSize: Int64? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.fileURL = fileURL
        self.fileName = fileURL.lastPathComponent
        self.fileSize = fileSize
        self.quality = quality
        self.outputFormat = outputFormat
        self.resolution = resolution
        self.progress = progress
        self.status = status
        self.estimatedSecondsRemaining = estimatedSecondsRemaining
        self.outputURL = outputURL
        self.outputFileSize = outputFileSize
        self.errorMessage = errorMessage
    }
}
