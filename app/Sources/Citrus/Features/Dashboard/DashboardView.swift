import AppKit
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var queue: QueueViewModel
    @Environment(\.openSettings) private var openSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var hasFinished: Bool {
        queue.jobs.contains { [.completed, .failed, .cancelled].contains($0.status) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if queue.waitingCount > 0 {
                RecipeControlsView()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
            }

            if queue.hasJobs {
                QueueListView()
            } else {
                ImportDropZone {
                    queue.chooseFiles()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }

            if queue.waitingCount > 0 {
                bottomBar
            }
        }
        .frame(width: 440, height: 500)
        .background(.regularMaterial)
        .overlay {
            if queue.isDropTargeted {
                Rectangle()
                    .strokeBorder(Color.citrusAccent, lineWidth: 2)
                    .background(Color.citrusAccent.opacity(0.06))
                    .allowsHitTesting(false)
            }
        }
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
            VStack(alignment: .leading, spacing: 2) {
                Text("Citrus")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                queue.chooseFiles()
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .help("Add files")
            .accessibilityLabel("Add files")

            Menu {
                Button("Add Files…") { queue.chooseFiles() }
                if hasFinished {
                    Button("Clear Finished") { queue.clearCompleted() }
                }
                Divider()
                Button("Settings…") { openSettings() }
                Divider()
                Button("Quit Citrus") { NSApplication.shared.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
            }
            .menuStyle(.button)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("More")
            .accessibilityLabel("More options")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.4)

            Button {
                queue.processWaitingJobs()
            } label: {
                Text(actionTitle)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Text("Saved to \(queue.destinationSummary)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 5)
                .padding(.bottom, 12)
        }
        .background(.regularMaterial)
    }

    private var actionTitle: String {
        let count = queue.waitingCount
        return "Compress \(count) File\(count == 1 ? "" : "s")"
    }

    private var subtitle: String {
        if queue.activeCount > 0 {
            return "Compressing \(queue.activeCount)…"
        }
        if queue.waitingCount > 0 {
            return "\(queue.waitingCount) ready"
        }
        if queue.completedCount > 0 {
            return "\(queue.completedCount) done · saved in \(queue.destinationSummary)"
        }
        return "Convert. Compress. Done."
    }
}
