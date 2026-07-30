import SwiftUI

struct CratesView: View {
    @EnvironmentObject var api: API
    @State private var search = ""

    private var roots: [Crate] {
        let list = api.crates.filter { !$0.stem.contains("%%") }
        return list.sorted { ($0.plays ?? 0) > ($1.plays ?? 0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    statTiles
                    gradeBar
                    LazyVStack(spacing: 2) {
                        ForEach(filtered) { crate in
                            NavigationLink(value: crate) { CrateRow(crate: crate) }
                        }
                    }
                    .card()
                }
                .padding(.horizontal, 14)
            }
            .background(Theme.bg0)
            .navigationTitle("VS")
            .navigationDestination(for: Crate.self) { CrateScreen(crate: $0) }
            .searchable(text: $search, prompt: "Search crates")
            .refreshable { await api.refresh() }
            .task { await api.refresh() }
            .overlay {
                if !api.online && api.crates.isEmpty {
                    ContentUnavailableView("Mac unreachable",
                        systemImage: "wifi.exclamationmark",
                        description: Text("Turn on Tailscale, then pull to retry."))
                }
            }
        }
    }

    private var filtered: [Crate] {
        search.isEmpty ? roots
            : api.crates.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var statTiles: some View {
        HStack(spacing: 10) {
            Tile(value: "\(api.summary.total)", label: "crates")
            Tile(value: "\(api.summary.avgScore)", label: "avg score")
            Tile(value: "\(api.summary.bsUnflagged)", label: "BS")
            Tile(value: "\(api.summary.empty)", label: "empty")
        }
    }

    private var gradeBar: some View {
        let order = ["A", "B", "C", "D", "F"]
        let total = max(order.compactMap { api.summary.grades[$0] }.reduce(0, +), 1)
        return VStack(alignment: .leading, spacing: 8) {
            Text("GRADES").font(.caption2.weight(.semibold)).foregroundStyle(Theme.mute).kerning(1)
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(order, id: \.self) { g in
                        let n = api.summary.grades[g] ?? 0
                        if n > 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.gradeColor(g))
                                .frame(width: max(geo.size.width * CGFloat(n) / CGFloat(total) - 2, 3))
                        }
                    }
                }
            }
            .frame(height: 14)
        }
        .card()
    }
}

struct Tile: View {
    let value: String, label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(Theme.ink2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.bg1)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
    }
}

struct CrateRow: View {
    let crate: Crate
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: crate.grade == "DIR" ? "folder.fill" : "square.stack.3d.up")
                .foregroundStyle(crate.grade == "DIR" ? Theme.accent : Theme.mute)
                .font(.system(size: 14))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(leaf).foregroundStyle(Theme.ink).lineLimit(1)
                    .font(.system(size: 15, weight: crate.grade == "DIR" ? .semibold : .regular))
                Text("\(crate.tracks) tracks · \(crate.plays ?? 0) plays")
                    .font(.caption2).foregroundStyle(Theme.mute).monospacedDigit()
            }
            Spacer()
            if crate.flagged { Text("✱").foregroundStyle(Theme.warn) }
            Text(crate.grade == "DIR" ? "▸" : crate.grade)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.gradeColor(crate.grade))
                .frame(width: 26)
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }
    private var leaf: String { crate.name.components(separatedBy: " > ").last ?? crate.name }
}

struct CrateScreen: View {
    let crate: Crate
    @EnvironmentObject var api: API
    @EnvironmentObject var player: Player
    @State private var tracks: [CrateTrack] = []
    @State private var children: [Crate] = []
    @State private var renaming = false
    @State private var newName = ""

    var body: some View {
        List {
            if !children.isEmpty {
                Section("Subcrates") {
                    ForEach(children) { c in
                        NavigationLink(value: c) { CrateRow(crate: c) }
                            .listRowBackground(Theme.bg1)
                    }
                }
            }
            if !tracks.isEmpty {
                Section("\(tracks.count) tracks") {
                    ForEach(Array(tracks.enumerated()), id: \.element.id) { i, t in
                        TrackRow(track: t, playing: player.current?.path == t.path)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                player.load(tracks, startAt: i, crate: crate.name, api: api)
                            }
                            .listRowBackground(Theme.bg1)
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task {
                                        await api.removeTrack(stem: crate.stem, path: t.path)
                                        tracks.removeAll { $0.path == t.path }
                                    }
                                } label: { Label("Remove", systemImage: "minus.circle") }
                            }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg0)
        .navigationTitle(crate.name.components(separatedBy: " > ").last ?? crate.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Crate.self) { CrateScreen(crate: $0) }
        .toolbar {
            Menu {
                Button("Rename") { newName = crate.name.components(separatedBy: " > ").last ?? ""; renaming = true }
                Button("Delete crate", role: .destructive) {
                    Task { await api.deleteCrate(stem: crate.stem) }
                }
            } label: { Image(systemName: "ellipsis.circle") }
        }
        .alert("Rename crate", isPresented: $renaming) {
            TextField("Name", text: $newName)
            Button("Rename") { Task { await api.renameCrate(stem: crate.stem, to: newName) } }
            Button("Cancel", role: .cancel) {}
        }
        .task {
            children = api.crates
                .filter { $0.stem.hasPrefix(crate.stem + "%%") && !$0.stem.dropFirst(crate.stem.count + 2).contains("%%") }
                .sorted { ($0.plays ?? 0) > ($1.plays ?? 0) }
            tracks = await api.detail(crate.stem)
        }
    }
}

struct TrackRow: View {
    let track: CrateTrack
    let playing: Bool
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.artGradient(track.name))
                .frame(width: 38, height: 38)
                .overlay {
                    if playing { Image(systemName: "waveform").foregroundStyle(.white).font(.caption) }
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name).lineLimit(1)
                    .font(.system(size: 14, weight: playing ? .semibold : .regular))
                    .foregroundStyle(playing ? Theme.accentSoft : Theme.ink)
                HStack(spacing: 6) {
                    if let bpm = track.bpm { Badge(text: "\(bpm) BPM") }
                    if let key = track.key { Badge(text: key) }
                    if let e = track.energy { Badge(text: "E\(e)") }
                    if !track.exists { Badge(text: "missing", color: Theme.critical) }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct Badge: View {
    let text: String
    var color: Color = Theme.mute
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold)).monospacedDigit()
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Theme.bg2)
            .foregroundStyle(color == Theme.mute ? Theme.ink2 : color)
            .clipShape(Capsule())
    }
}
