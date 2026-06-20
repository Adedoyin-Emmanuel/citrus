import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class QueueViewModel: ObservableObject {
    @Published private(set) var jobs: [MediaJob] = []
    @Published var isDropTargeted = false
    @Published var importError: String?
    @Published var selectedQuality: QualityPreference
    @Published var selectedFormat: OutputFormat = .keepOriginal
    @Published var selectedResolution: ResolutionOption = .original
    @Published var hasPendingConfiguration = false
    var onImportCompleted: (() -> Void)?

    private let processor: MediaProcessing
    private let notificationCenter: CitrusNotificationCenter
    private let settingsStore: SettingsStore
    private var tasks: [UUID: Task<Void, Never>] = [:]
    private var openPanel: NSOpenPanel?
    private var batchDestinationDirectory: URL?

    init(
        processor: MediaProcessing,
        notificationCenter: CitrusNotificationCenter,
        settingsStore: SettingsStore
    ) {
        self.processor = processor
        self.notificationCenter = notificationCenter
        self.settingsStore = settingsStore
        self.selectedQuality = settingsStore.defaultQuality
    }

    var hasJobs: Bool { !jobs.isEmpty }
    var activeCount: Int { jobs.filter { $0.status == .processing }.count }
    var waitingCount: Int { jobs.filter { $0.status == .waiting }.count }
    var completedCount: Int { jobs.filter { $0.status == .completed }.count }

    /// Human-readable description of where finished files will be written,
    /// used to tell the user up front where to find their export.
    var destinationSummary: String {
        switch settingsStore.outputLocationChoice {
        case .sourceFolder: "the original folder"
        case .downloads: "Downloads"
        case .askEveryTime: "a folder you choose"
        }
    }

    func importURLs(_ urls: [URL]) {
        let supported = urls.filter(SupportedMedia.isSupported)
        let rejectedCount = urls.count - supported.count

        if rejectedCount > 0 {
            importError = "\(rejectedCount) unsupported file\(rejectedCount == 1 ? "" : "s") skipped."
        } else {
            importError = nil
        }

        let newJobs = supported.map(makeJob)
        jobs.append(contentsOf: newJobs)
        if !newJobs.isEmpty {
            hasPendingConfiguration = true
        }
    }

    func processWaitingJobs() {
        if settingsStore.outputLocationChoice == .askEveryTime,
           !promptForBatchDestination() {
            return
        }

        applyCurrentSettingsToWaitingJobs()
        hasPendingConfiguration = false

        let waitingIDs = jobs
            .filter { $0.status == .waiting }
            .map(\.id)

        for jobID in waitingIDs {
            start(jobID: jobID)
        }
    }

    /// Asks once, for the whole batch, where finished files should land.
    /// Returns false if the user cancels so processing can be aborted.
    private func promptForBatchDestination() -> Bool {
        let panel = NSOpenPanel()
        panel.title = "Choose export folder"
        panel.prompt = "Export Here"
        panel.message = "Choose where Citrus should save your optimized files."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let directory = panel.url else { return false }
        batchDestinationDirectory = directory
        return true
    }

    func cancel(_ job: MediaJob) {
        tasks[job.id]?.cancel()
        tasks[job.id] = nil
        update(job.id) {
            $0.status = .cancelled
            $0.estimatedSecondsRemaining = nil
        }
    }

    func remove(_ job: MediaJob) {
        tasks[job.id]?.cancel()
        tasks[job.id] = nil
        jobs.removeAll { $0.id == job.id }
    }

    func clearCompleted() {
        jobs.removeAll { $0.status == .completed || $0.status == .failed || $0.status == .cancelled }
    }

    func chooseFiles() {
        guard openPanel == nil else {
            openPanel?.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSOpenPanel()
        openPanel = panel
        panel.title = "Choose videos"
        panel.prompt = "Add"
        panel.message = "Choose videos to compress with Citrus."
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .movie,
            .video,
            .mpeg4Movie,
            .quickTimeMovie,
            UTType(filenameExtension: "m4v"),
            UTType(filenameExtension: "mkv"),
            UTType(filenameExtension: "avi"),
            UTType(filenameExtension: "webm")
        ].compactMap { $0 }

        NSApp.activate(ignoringOtherApps: true)
        panel.begin { [weak self] response in
            Task { @MainActor in
                defer { self?.openPanel = nil }
                self?.onImportCompleted?()
                guard response == .OK else { return }
                self?.importURLs(panel.urls)
                self?.onImportCompleted?()
            }
        }
    }

    func revealOutput(_ job: MediaJob) {
        guard let outputURL = job.outputURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }

    private func makeJob(for url: URL) -> MediaJob {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        return MediaJob(
            fileURL: url,
            fileSize: size,
            quality: selectedQuality,
            outputFormat: selectedFormat,
            resolution: selectedResolution
        )
    }

    private func applyCurrentSettingsToWaitingJobs() {
        for index in jobs.indices where jobs[index].status == .waiting {
            jobs[index].quality = selectedQuality
            jobs[index].outputFormat = selectedFormat
            jobs[index].resolution = selectedResolution
        }
    }

    /// Resolves the folder finished files are written to, honoring the user's
    /// output-location preference. `.askEveryTime` uses the folder chosen for the
    /// current batch, falling back to the source folder if none was picked.
    private func destinationDirectory(for job: MediaJob) -> URL {
        switch settingsStore.outputLocationChoice {
        case .sourceFolder:
            return job.fileURL.deletingLastPathComponent()
        case .downloads:
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                ?? job.fileURL.deletingLastPathComponent()
        case .askEveryTime:
            return batchDestinationDirectory ?? job.fileURL.deletingLastPathComponent()
        }
    }

    /// Builds a clean, unbranded destination URL using the format Citrus will
    /// actually encode, adding a numeric suffix only when needed so we never
    /// overwrite the original or a previous export.
    private func exportURL(for job: MediaJob) -> URL {
        let directory = destinationDirectory(for: job)
        let baseName = job.fileURL.deletingPathExtension().lastPathComponent
        let ext = job.outputFormat.resolvedExtension(sourceExtension: job.fileURL.pathExtension)

        var candidate = directory.appendingPathComponent("\(baseName).\(ext)")
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName) \(counter).\(ext)")
            counter += 1
        }
        return candidate
    }

    private func start(jobID: UUID) {
        guard let job = jobs.first(where: { $0.id == jobID }) else { return }
        let destination = exportURL(for: job)

        tasks[jobID] = Task { [processor, notificationCenter, weak self] in
            await MainActor.run {
                self?.update(jobID) { $0.status = .processing }
            }

            do {
                for try await update in processor.process(job: job, to: destination) {
                    await MainActor.run {
                        self?.update(jobID) {
                            $0.progress = update.progress
                            $0.estimatedSecondsRemaining = update.estimatedSecondsRemaining
                        }
                    }
                }

                let outputSize = (try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)

                await MainActor.run {
                    self?.tasks[jobID] = nil
                    self?.update(jobID) {
                        $0.status = .completed
                        $0.progress = 1
                        $0.estimatedSecondsRemaining = nil
                        $0.outputURL = destination
                        $0.outputFileSize = outputSize
                    }
                }

                if self?.settingsStore.notificationsEnabled == true {
                    await notificationCenter.notifyJobCompleted(fileName: job.fileName)
                }
            } catch {
                await MainActor.run {
                    self?.tasks[jobID] = nil
                    self?.update(jobID) {
                        $0.status = error.localizedDescription == ProcessingError.cancelled.localizedDescription ? .cancelled : .failed
                        $0.errorMessage = error.localizedDescription
                        $0.estimatedSecondsRemaining = nil
                    }
                }
            }
        }
    }

    private func update(_ jobID: UUID, mutation: (inout MediaJob) -> Void) {
        guard let index = jobs.firstIndex(where: { $0.id == jobID }) else { return }
        mutation(&jobs[index])
    }
}
