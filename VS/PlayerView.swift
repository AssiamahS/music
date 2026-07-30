import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var api: API
    @EnvironmentObject var player: Player

    var body: some View {
        VStack(spacing: 0) {
            if let t = player.current {
                nowPlaying(t)
            } else {
                ContentUnavailableView("Nothing playing",
                    systemImage: "play.square.stack",
                    description: Text("Open a crate and tap a track."))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg0)
    }

    @ViewBuilder
    private func nowPlaying(_ t: CrateTrack) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)

            // artwork
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.artGradient(t.name))
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .bottomLeading) {
                    HStack(spacing: 6) {
                        if let bpm = t.bpm { Badge(text: "\(bpm) BPM") }
                        if let key = t.key { Badge(text: key) }
                        if let e = t.energy { Badge(text: "E\(e)") }
                    }
                    .padding(12)
                }
                .shadow(color: .black.opacity(0.6), radius: 24, y: 12)
                .padding(.horizontal, 28)
                .scaleEffect(player.playing ? 1.0 : 0.94)
                .animation(.spring(duration: 0.35), value: player.playing)

            // title
            VStack(spacing: 4) {
                Text(title(t)).font(.title3.weight(.bold)).foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(artist(t)).font(.subheadline).foregroundStyle(Theme.ink2).lineLimit(1)
                Text(player.crateName).font(.caption).foregroundStyle(Theme.mute)
            }
            .padding(.horizontal, 28)

            // scrubber
            VStack(spacing: 4) {
                Slider(value: Binding(
                    get: { min(player.progress, player.duration) },
                    set: { player.seek(to: $0) }
                ), in: 0...player.duration)
                HStack {
                    Text(clock(player.progress))
                    Spacer()
                    Text(clock(player.duration))
                }
                .font(.caption2).monospacedDigit().foregroundStyle(Theme.mute)
            }
            .padding(.horizontal, 28)

            // transport — liquid glass pad
            GlassEffectContainer {
                HStack(spacing: 44) {
                    Button { player.prev(api: api) } label: {
                        Image(systemName: "backward.fill").font(.system(size: 24))
                            .frame(width: 56, height: 56)
                    }
                    .glassEffect(.regular.interactive())
                    Button { player.toggle() } label: {
                        Image(systemName: player.playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 34))
                            .frame(width: 84, height: 84)
                    }
                    .glassEffect(.regular.tint(Theme.accent.opacity(0.35)).interactive())
                    Button { player.next(api: api) } label: {
                        Image(systemName: "forward.fill").font(.system(size: 24))
                            .frame(width: 56, height: 56)
                    }
                    .glassEffect(.regular.interactive())
                }
            }
            .foregroundStyle(Theme.ink)

            // up next
            if player.index + 1 < player.queue.count {
                let n = player.queue[player.index + 1]
                HStack(spacing: 8) {
                    Text("Up next").font(.caption2).foregroundStyle(Theme.mute)
                    Text(title(n)).font(.caption).foregroundStyle(Theme.ink2).lineLimit(1)
                }
                .padding(.horizontal, 28)
            }
            Spacer(minLength: 8)
        }
    }

    private func title(_ t: CrateTrack) -> String {
        t.name.components(separatedBy: " - ").dropFirst().joined(separator: " - ").isEmpty
            ? t.name
            : t.name.components(separatedBy: " - ").dropFirst().joined(separator: " - ")
    }
    private func artist(_ t: CrateTrack) -> String {
        t.name.components(separatedBy: " - ").first ?? ""
    }
    private func clock(_ s: Double) -> String {
        guard s.isFinite else { return "0:00" }
        return String(format: "%d:%02d", Int(s) / 60, Int(s) % 60)
    }
}
