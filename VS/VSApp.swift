import SwiftUI

@main
struct VSApp: App {
    @StateObject private var api = API()
    @StateObject private var player = Player()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(api)
                .environmentObject(player)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var player: Player

    var body: some View {
        TabView {
            CratesView()
                .tabItem { Label("Crates", systemImage: "square.stack.3d.up.fill") }
            PlayerView()
                .tabItem { Label("Player", systemImage: "play.circle.fill") }
            ListenView()
                .tabItem { Label("Listen", systemImage: "headphones") }
            JobsView()
                .tabItem { Label("Jobs", systemImage: "waveform.path.ecg") }
        }
        .background(Theme.bg0)
    }
}
