import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class QueueViewModel: ObservableObject {
    @Published private(set) var jobs: [MediaJob] = []
    @Published var isDropTargeted = false
    @Published var importError: String?

    private let processor: MediaProcessing
    private let notificationCenter: CitrusNotificationCenter
    private let settingsStore: SettingsStore
    private var tasks: [UUID: Task<Void, Never>] = [:]

    init(
        processor: MediaProcessing,
        notificationCenter: CitrusNotificationCenter,
        settingsStore: SettingsStore
    ) {
        self.processor = processor
        self.notificationCenter = notificationCenter
        self.settingsStore = settingsStore
    }

    var hasJobs: Bool { !jobs.isEmpty }
    var activeCount: Int { jobs.filter { $0.status == .processing || $0.status == .waiting }.count }

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
        for job in newJobs {
            start(jobID: job.id)
        }
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .png,
            .jpeg,
            UTType(filenameExtension: "webp"),
            UTType(filenameExtension: "heic"),
            UTType(filenameExtension: "avif"),
            .mpeg4Movie,
            .quickTimeMovie,
            UTType(filenameExtension: "mkv"),
            UTType(filenameExtension: "avi"),
            UTType(filenameExtension: "webm")
        ].compactMap { $0 }

        if panel.runModal() == .OK {
            importURLs(panel.urls)
        }
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

    private func makeJob(for url: URL) -> MediaJob {
        let kind = SupportedMedia.kind(for: url)
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        let preset = kind == .image ? settingsStore.defaultImagePreset : settingsStore.defaultVideoPreset
        return MediaJob(fileURL: url, fileSize: size, mediaKind: kind, preset: preset)
    }

    private func start(jobID: UUID) {
        guard let job = jobs.first(where: { $0.id == jobID }) else { return }

        tasks[jobID] = Task { [processor, notificationCenter, weak self] in
            await MainActor.run {
                self?.update(jobID) { $0.status = .processing }
            }

            do {
                for try await update in processor.process(job: job) {
                    await MainActor.run {
                        self?.update(jobID) {
                            $0.progress = update.progress
                            $0.estimatedSecondsRemaining = update.estimatedSecondsRemaining
                        }
                    }
                }

                await MainActor.run {
                    self?.tasks[jobID] = nil
                    self?.update(jobID) {
                        $0.status = .completed
                        $0.progress = 1
                        $0.estimatedSecondsRemaining = nil
                    }
                }

                if self?.settingsStore.notificationsEnabled == true {
                    await notificationCenter.requestAuthorizationIfNeeded()
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
