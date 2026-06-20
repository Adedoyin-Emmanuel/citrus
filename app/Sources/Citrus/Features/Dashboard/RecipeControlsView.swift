import SwiftUI

struct RecipeControlsView: View {
    @EnvironmentObject private var queue: QueueViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quality")
                .font(.subheadline.weight(.semibold))

            Picker("Quality", selection: $queue.selectedQuality) {
                ForEach(QualityPreference.allCases) { quality in
                    Text(quality.title).tag(quality)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.large)

            Text(queue.selectedQuality.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Menu {
                    Picker("Format", selection: $queue.selectedFormat) {
                        ForEach(OutputFormat.videoFormats) { format in
                            Text(format.title).tag(format)
                        }
                    }
                } label: {
                    ControlLabel(title: queue.selectedFormat.title, systemImage: "film")
                }
                .menuStyle(.button)
                .accessibilityLabel("Video format")

                Menu {
                    Picker("Resolution", selection: $queue.selectedResolution) {
                        ForEach(ResolutionOption.allCases) { resolution in
                            Text(resolution.title).tag(resolution)
                        }
                    }
                } label: {
                    ControlLabel(title: queue.selectedResolution.title, systemImage: "aspectratio")
                }
                .menuStyle(.button)
                .accessibilityLabel("Resolution")
            }
            .padding(.top, 2)
        }
    }
}

private struct ControlLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.callout.weight(.medium))
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
    }
}
