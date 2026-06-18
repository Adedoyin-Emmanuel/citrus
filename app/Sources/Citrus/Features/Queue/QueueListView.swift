import SwiftUI

struct QueueListView: View {
    @EnvironmentObject private var queue: QueueViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(queue.jobs) { job in
                    QueueRowView(job: job)
                }
            }
            .padding(12)
        }
        .frame(minHeight: 300)
    }
}
