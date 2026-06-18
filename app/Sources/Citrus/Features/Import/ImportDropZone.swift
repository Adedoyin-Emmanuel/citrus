import SwiftUI

struct ImportDropZone: View {
    @EnvironmentObject private var queue: QueueViewModel

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 12)

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        queue.isDropTargeted ? Color.citrusAccent : Color.secondary.opacity(0.22),
                        style: StrokeStyle(lineWidth: 1.5, dash: [7, 7])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(queue.isDropTargeted ? Color.citrusAccent.opacity(0.10) : Color.clear)
                    )

                VStack(spacing: 14) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 36, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(queue.isDropTargeted ? Color.citrusAccent : .secondary)

                    VStack(spacing: 5) {
                        Text("Drop media to optimize")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                        Text("Images and videos stay local on your Mac.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        queue.chooseFiles()
                    } label: {
                        Label("Choose Files", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(26)
            }
            .frame(height: 255)

            PresetStrip()

            Spacer(minLength: 8)
        }
    }
}
