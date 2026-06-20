import SwiftUI

/// A slim, capsule-shaped determinate progress bar — quieter and more premium
/// than the stock linear ProgressView.
struct CitrusProgressBar: View {
    var value: Double
    var tint: Color
    var height: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.quaternary)
                Capsule(style: .continuous)
                    .fill(tint)
                    .frame(width: proxy.size.width * max(0, min(1, value)))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
