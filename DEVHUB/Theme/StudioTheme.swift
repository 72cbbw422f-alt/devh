import SwiftUI
enum StudioTheme {
    static let background = Color(hex:"0B0E14")
    static let surface = Color(hex:"111720")
    static let elevated = Color(hex:"171F2B")
    static let border = Color(hex:"252F3D")
    static let muted = Color(hex:"8793A4")
    static let lime = Color(hex:"B6EF70")
}
extension Color {
    init(hex: String) {
        let value = Int(hex, radix:16) ?? 0
        self.init(.sRGB, red:Double((value >> 16) & 255)/255, green:Double((value >> 8) & 255)/255, blue:Double(value & 255)/255, opacity:1)
    }
}
