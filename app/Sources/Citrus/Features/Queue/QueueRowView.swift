import SwiftUI

struct QueueRowView: View {
    @EnvironmentObject private var queue: QueueViewModel
    let job: MediaJob

    var body: some View {
        HStack(spacing: 12) {
            fileIcon

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(job.fileName)
                            .font(.callout.weight(.medium))
                            .lineLimit(1)
                        Text("\(job.fileSize.citrusFileSize) • \(job.preset.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(statusText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(statusColor)
                }

                ProgressView(value: job.progress)
                    .progressViewStyle(.linear)
                    .tint(statusColor)
            }

            actionButton
        }
        .padding(12)
        .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var fileIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(statusColor.opacity(0.13))
            Image(systemName: job.mediaKind == .image ? "photo" : "film")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(statusColor)
        }
        .frame(width: 34, height: 34)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch job.status {
        case .waiting, .processing:
            Button {
                queue.cancel(job)
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Cancel \(job.fileName)")
        case .completed, .failed, .cancelled:
            Button {
                queue.remove(job)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove \(job.fileName)")
        }
    }

    private var statusText: String {
        if job.status == .processing, let seconds = job.estimatedSecondsRemaining {
            return seconds.citrusDuration
        }
        return job.status.title
    }

    private var statusColor: Color {
        switch job.status {
        case .waiting: .secondary
        case .processing: .citrusAccent
        case .completed: .green
        case .failed: .red
        case .cancelled: .orange
        }
    }
}
