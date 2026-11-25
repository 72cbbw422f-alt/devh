import SwiftUI
enum StudioTheme {
    static let background = Color(hex:"F3F5F7")
    static let surface = Color(hex:"FFFFFF")
    static let elevated = Color(hex:"E9EEF3")
    static let border = Color(hex:"E0E5EB")
    static let muted = Color(hex:"738092")
    static let text = Color(hex:"202B38")
    static let secondaryText = Color(hex:"526173")
    static let accent = Color(hex:"587B9D")
}
extension Color {
    init(hex: String) {
        let value = Int(hex, radix:16) ?? 0
        self.init(.sRGB, red:Double((value >> 16) & 255)/255, green:Double((value >> 8) & 255)/255, blue:Double(value & 255)/255, opacity:1)
    }
}