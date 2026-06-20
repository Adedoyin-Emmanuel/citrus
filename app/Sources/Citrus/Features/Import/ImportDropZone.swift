import SwiftUI

struct ImportDropZone: View {
    @EnvironmentObject private var queue: QueueViewModel
    let chooseFiles: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    queue.isDropTargeted ? Color.citrusAccent : Color.secondary.opacity(0.22),
                    style: StrokeStyle(lineWidth: 1.4, dash: [6, 6])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(queue.isDropTargeted ? Color.citrusAccent.opacity(0.08) : Color.clear)
                )

            VStack(spacing: 12) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 32, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(queue.isDropTargeted ? Color.citrusAccent : .secondary)

                VStack(spacing: 4) {
                    Text("Drop a video")
                        .font(.system(.headline, design: .rounded))
                    Text("Compressed locally on your Mac.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Button("Choose Videos", action: chooseFiles)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .padding(.top, 2)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
