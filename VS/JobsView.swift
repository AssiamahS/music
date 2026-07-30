import SwiftUI

struct JobsView: View {
    @EnvironmentObject var api: API
    @State private var timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(api.jobs) { job in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(color(job.status))
                                .frame(width: 9, height: 9)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(job.name).font(.system(size: 15, weight: .semibold))
                                Text(job.last.isEmpty ? job.status : job.last)
                                    .font(.caption).foregroundStyle(Theme.ink2)
                                    .lineLimit(2).monospacedDigit()
                            }
                            Spacer()
                            Text(job.status.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(color(job.status))
                        }
                        .card()
                    }
                    if api.jobs.isEmpty {
                        ContentUnavailableView("No jobs reported",
                            systemImage: "moon.zzz",
                            description: Text("Pull to refresh — jobs appear when the Mac is reachable."))
                    }
                }
                .padding(14)
            }
            .background(Theme.bg0)
            .navigationTitle("Jobs")
            .refreshable { await api.refreshJobs() }
            .task { await api.refreshJobs() }
            .onReceive(timer) { _ in Task { await api.refreshJobs() } }
        }
    }

    private func color(_ s: String) -> Color {
        switch s {
        case "running": return Theme.accent
        case "done": return Theme.good
        case "info": return Theme.ink2
        default: return Theme.mute
        }
    }
}
