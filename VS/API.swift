import Foundation

struct Summary: Codable {
    var total = 0, folders = 0, avgScore = 0, flagged = 0, bsUnflagged = 0, empty = 0
    var grades: [String: Int] = [:]
}

struct Crate: Codable, Identifiable, Hashable {
    var id: String { stem }
    let name: String
    let stem: String
    let tracks: Int
    let plays: Int?
    let score: Int
    let grade: String
    let flagged: Bool
    let hasChildren: Bool
    var isFolder: Bool? = nil
}

struct CrateTrack: Codable, Identifiable, Hashable {
    var id: String { path }
    let path: String
    let name: String
    let exists: Bool
    let bpm: Int?
    let key: String?
    let energy: Int?
    let plays: Int?
}

struct Job: Codable, Identifiable {
    var id: String { name }
    let name: String
    let status: String
    let last: String
}

struct CratesPayload: Codable { let summary: Summary; let crates: [Crate] }
struct CrateDetail: Codable { let stem: String; let tracks: [CrateTrack] }
struct JobsPayload: Codable { let jobs: [Job] }

@MainActor
final class API: ObservableObject {
    static let host = "saints-macbook-air.tail40af16.ts.net"
    static let base = URL(string: "http://\(host):8795")!

    @Published var summary = Summary()
    @Published var crates: [Crate] = []
    @Published var jobs: [Job] = []
    @Published var online = false

    func audioURL(_ path: String) -> URL {
        var c = URLComponents(url: Self.base.appendingPathComponent("audio"), resolvingAgainstBaseURL: false)!
        c.queryItems = [URLQueryItem(name: "path", value: path)]
        return c.url!
    }

    private func get<T: Codable>(_ path: String, _ type: T.Type, query: [URLQueryItem] = []) async throws -> T {
        var c = URLComponents(url: Self.base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { c.queryItems = query }
        let (data, _) = try await URLSession.shared.data(from: c.url!)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post(_ path: String, body: [String: String]) async throws {
        var req = URLRequest(url: Self.base.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: req)
    }

    func refresh() async {
        do {
            let p = try await get("api/crates", CratesPayload.self)
            summary = p.summary
            crates = p.crates
            online = true
        } catch { online = false }
    }

    func detail(_ stem: String) async -> [CrateTrack] {
        (try? await get("api/crate", CrateDetail.self, query: [URLQueryItem(name: "stem", value: stem)]))?.tracks ?? []
    }

    func refreshJobs() async {
        jobs = (try? await get("api/jobs", JobsPayload.self))?.jobs ?? jobs
    }

    func removeTrack(stem: String, path: String) async {
        try? await post("api/crate/remove-track", body: ["stem": stem, "path": path])
    }

    func renameCrate(stem: String, to newLeaf: String) async {
        try? await post("api/crate/rename", body: ["stem": stem, "newLeaf": newLeaf])
        await refresh()
    }

    func deleteCrate(stem: String) async {
        try? await post("api/crate/delete", body: ["stem": stem])
        await refresh()
    }

    func download(url: String) async {
        try? await post("api/listen-download", body: ["url": url])
    }
}
