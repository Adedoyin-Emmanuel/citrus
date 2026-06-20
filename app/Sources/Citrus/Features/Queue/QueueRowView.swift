import SwiftUI

struct QueueRowView: View {
    @EnvironmentObject private var queue: QueueViewModel
    let job: MediaJob

    var body: some View {
        HStack(spacing: 12) {
            fileIcon

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(job.fileName)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer(minLength: 8)

                    Text(statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                        .monospacedDigit()
                }

                Text(detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if job.status == .processing {
                    CitrusProgressBar(value: job.progress, tint: statusColor)
                        .padding(.top, 2)
                }
            }

            actionButton
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var fileIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(statusColor.opacity(0.14))
            Image(systemName: "film")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(statusColor)
        }
        .frame(width: 32, height: 32)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch job.status {
        case .waiting, .processing:
            iconButton("xmark", label: "Cancel \(job.fileName)") { queue.cancel(job) }
        case .completed:
            HStack(spacing: 2) {
                iconButton("arrow.up.forward.square", label: "Open \(job.fileName) in Finder", help: "Open in Finder") {
                    queue.revealOutput(job)
                }
                iconButton("trash", label: "Remove \(job.fileName)") { queue.remove(job) }
            }
        case .failed, .cancelled:
            iconButton("trash", label: "Remove \(job.fileName)") { queue.remove(job) }
        }
    }

    private func iconButton(
        _ systemName: String,
        label: String,
        help: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.callout)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .help(help ?? label)
        .accessibilityLabel(label)
    }

    private var statusText: String {
        switch job.status {
        case .processing:
            return "\(Int(job.progress * 100))%"
        case .completed:
            if let percent = savingsPercent {
                return percent > 0 ? "−\(percent)%" : "Done"
            }
            return "Done"
        default:
            return job.status.title
        }
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

    private var detailText: String {
        switch job.status {
        case .waiting:
            "\(job.fileSize.citrusFileSize) - ready"
        case .processing:
            "\(job.fileSize.citrusFileSize) - compressing…"
        case .completed:
            if let outputSize = job.outputFileSize {
                "\(job.fileSize.citrusFileSize) -> \(outputSize.citrusFileSize)"
            } else {
                "Done"
            }
        case .failed:
            job.errorMessage ?? "Failed"
        case .cancelled:
            "Cancelled"
        }
    }

    private var savingsPercent: Int? {
        guard let outputSize = job.outputFileSize, job.fileSize > 0 else { return nil }
        let ratio = 1 - (Double(outputSize) / Double(job.fileSize))
        return max(0, Int((ratio * 100).rounded()))
    }
}
