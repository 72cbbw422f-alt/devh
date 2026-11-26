import SwiftUI

enum StudioTheme {
    // DEVHUB — Midnight / Indigo Premium
    static let background = Color(hex: "080D1F")
    static let surface = Color(hex: "111A35")
    static let elevated = Color(hex: "1A2648")
    static let border = Color(hex: "29385F")
    static let muted = Color(hex: "8793B5")
    static let text = Color(hex: "F3F5FF")
    static let secondaryText = Color(hex: "B8C2E0")
    static let accent = Color(hex: "7164F2")
    static let accentBlue = Color(hex: "398BFF")
    static let accentCyan = Color(hex: "45C6D9")
}

extension Color {
    init(hex: String) {
        let value = Int(hex, radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double((value >> 16) & 255) / 255,
            green: Double((value >> 8) & 255) / 255,
            blue: Double(value & 255) / 255,
            opacity: 1
        )
    }
}
