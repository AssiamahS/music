import AVFoundation
import Combine
import SwiftUI

@MainActor
final class Player: ObservableObject {
    @Published var queue: [CrateTrack] = []
    @Published var index = 0
    @Published var playing = false
    @Published var progress: Double = 0
    @Published var duration: Double = 1
    @Published var crateName = ""

    private var av = AVPlayer()
    private var timeObserver: Any?

    var current: CrateTrack? { queue.indices.contains(index) ? queue[index] : nil }

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func load(_ tracks: [CrateTrack], startAt i: Int, crate: String, api: API) {
        queue = tracks
        crateName = crate
        index = i
        start(api: api)
    }

    private func start(api: API) {
        guard let t = current else { return }
        if let ob = timeObserver { av.removeTimeObserver(ob); timeObserver = nil }
        let item = AVPlayerItem(url: api.audioURL(t.path))
        av.replaceCurrentItem(with: item)
        av.play()
        playing = true
        timeObserver = av.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                self.progress = time.seconds
                if let d = self.av.currentItem?.duration.seconds, d.isFinite { self.duration = max(d, 1) }
                if self.duration > 1, self.progress >= self.duration - 0.6 { self.next(api: api) }
            }
        }
    }

    func toggle() {
        if playing { av.pause() } else { av.play() }
        playing.toggle()
    }

    func seek(to seconds: Double) {
        av.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func next(api: API) {
        guard index + 1 < queue.count else { av.pause(); playing = false; return }
        index += 1
        start(api: api)
    }

    func prev(api: API) {
        if progress > 4 { seek(to: 0); return }
        guard index > 0 else { seek(to: 0); return }
        index -= 1
        start(api: api)
    }
}
