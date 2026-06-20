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
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 16)
        }
        .frame(maxHeight: .infinity)
        .scrollIndicators(.never)
    }
}
