import SwiftUI

// Pro booth dark — near-black surfaces, one electric blue, status colors
// reserved for grades. Matches the visualSerato dashboard.
enum Theme {
    static let bg0 = Color(red: 0.071, green: 0.071, blue: 0.067)      // #121211
    static let bg1 = Color(red: 0.102, green: 0.102, blue: 0.098)      // #1a1a19
    static let bg2 = Color(red: 0.137, green: 0.137, blue: 0.133)      // #232322
    static let border = Color(red: 0.196, green: 0.196, blue: 0.184)   // #32322f
    static let ink = Color.white
    static let ink2 = Color(red: 0.764, green: 0.760, blue: 0.717)     // #c3c2b7
    static let mute = Color(red: 0.541, green: 0.537, blue: 0.498)     // #8a897f
    static let accent = Color(red: 0.223, green: 0.529, blue: 0.898)   // #3987e5
    static let accentSoft = Color(red: 0.525, green: 0.713, blue: 0.937)

    static let good = Color(red: 0.047, green: 0.639, blue: 0.047)     // #0ca30c
    static let warn = Color(red: 0.980, green: 0.698, blue: 0.098)     // #fab219
    static let serious = Color(red: 0.925, green: 0.513, blue: 0.352)  // #ec835a
    static let critical = Color(red: 0.815, green: 0.231, blue: 0.231) // #d03b3b

    static func gradeColor(_ g: String) -> Color {
        switch g {
        case "A": return good
        case "B": return accent
        case "C": return warn
        case "D": return serious
        case "F": return critical
        default: return ink2
        }
    }

    // deterministic artwork gradient per track name — every song gets a cover
    static func artGradient(_ seed: String) -> LinearGradient {
        var h: UInt64 = 1469598103934665603
        for b in seed.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        let hue1 = Double(h % 360) / 360.0
        let hue2 = Double((h >> 16) % 360) / 360.0
        return LinearGradient(
            colors: [Color(hue: hue1, saturation: 0.55, brightness: 0.55),
                     Color(hue: hue2, saturation: 0.70, brightness: 0.22)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension View {
    func card() -> some View {
        self.padding(14)
            .background(Theme.bg1)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
    }
}
