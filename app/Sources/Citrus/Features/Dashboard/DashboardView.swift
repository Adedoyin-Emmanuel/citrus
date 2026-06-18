import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var queue: QueueViewModel
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.openSettings) private var openSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if queue.hasJobs {
                QueueListView()
            } else {
                ImportDropZone()
                    .padding(18)
            }

            Divider()

            footer
        }
        .frame(width: 420)
        .frame(minHeight: 430)
        .background(.regularMaterial)
        .dropDestination(for: URL.self) { urls, _ in
            queue.importURLs(urls)
            return true
        } isTargeted: { targeted in
            if reduceMotion {
                queue.isDropTargeted = targeted
            } else {
                withAnimation(.snappy(duration: 0.18)) {
                    queue.isDropTargeted = targeted
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.citrusAccent.gradient)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("Citrus")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                Text(queue.activeCount == 0 ? "Convert. Compress. Done." : "\(queue.activeCount) active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                queue.chooseFiles()
            } label: {
                Label("Choose Files", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .accessibilityLabel("Choose files")
        }
        .padding(16)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if let importError = queue.importError {
                Label(importError, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("\(settings.defaultImagePreset.title) for images")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button("Clear Done") {
                queue.clearCompleted()
            }
            .controlSize(.small)
            .disabled(!queue.jobs.contains { [.completed, .failed, .cancelled].contains($0.status) })

            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Open settings")
        }
        .padding(12)
    }
}
