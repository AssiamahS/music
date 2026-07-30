import SwiftUI
import WebKit

// The listen station — same page the Mac serves, wrapped natively with a
// paste-to-add bar so adding a playlist from the phone is one gesture.
struct ListenView: View {
    @EnvironmentObject var api: API
    @State private var pasted = ""
    @State private var toast: String?

    var body: some View {
        NavigationStack {
            WebView(url: API.base.appendingPathComponent("listen"))
                .background(Theme.bg0)
                .navigationTitle("Listen")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button {
                        if let s = UIPasteboard.general.string,
                           s.contains("spotify.com") || s.contains("soundcloud.com") {
                            Task {
                                await api.download(url: s)
                                toast = "Queued — lands in your library"
                            }
                        } else {
                            toast = "Copy a Spotify/SoundCloud link first"
                        }
                    } label: { Image(systemName: "arrow.down.circle.fill") }
                }
                .overlay(alignment: .bottom) {
                    if let t = toast {
                        Text(t)
                            .font(.footnote)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Theme.bg2, in: Capsule())
                            .padding(.bottom, 12)
                            .task {
                                try? await Task.sleep(for: .seconds(3))
                                toast = nil
                            }
                    }
                }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.isOpaque = false
        wv.backgroundColor = .black
        wv.load(URLRequest(url: url))
        return wv
    }
    func updateUIView(_ wv: WKWebView, context: Context) {}
}
