import SwiftUI

struct PresetStrip: View {
    private let presets: [ProcessingPreset] = [.makeSmaller, .webOptimized, .emailFriendly]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(presets) { preset in
                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.title)
                        .font(.caption.weight(.semibold))
                    Text(preset.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}
