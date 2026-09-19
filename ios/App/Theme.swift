/// The web build's style.css palette, ported.
import SwiftUI
import ExpressionPadCore

enum Theme {
    static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
    static let bg = adaptive(0xc5c4bb, 0x191c1a)
    static let caseTop = adaptive(0xe8e7df, 0x343a33)
    static let caseBottom = adaptive(0xd5d5cb, 0x252b26)
    static let line = adaptive(0xb1b1a6, 0x535b50)
    static let accent = Color(hex: 0xe95324)
    static let accentDim = adaptive(0x657354, 0x96a486)
    static let text = adaptive(0x292b27, 0xe2e5d9)
    static let textDim = adaptive(0x555d4e, 0xbac3b0)
    static let widgetBg = Color(hex: 0x343d2e)
    static let screenInk = Color(hex: 0xdce3c9)
    static let padBg = adaptive(0xb1bb9d, 0x283020)
    static let keyTop = adaptive(0xf5f3e9, 0x4a5343)
    static let keyBottom = adaptive(0xe3e1d7, 0x353e31)
    static let keyEdge = adaptive(0xa7a89d, 0x69745d)
    static let highlight = adaptive(0xfffdf2, 0x65705e)
    static let skirt = adaptive(0xaaa79c, 0x161d15)

    static func font(_ size: CGFloat) -> Font {
        .custom("IBMPlexSans-Regular", size: size, relativeTo: .body)
    }
    static func fontMedium(_ size: CGFloat) -> Font { font(size).weight(.semibold) }
    static func mono(_ size: CGFloat) -> Font {
        .custom("IBMPlexMono-Regular", size: size, relativeTo: .caption)
    }
}

struct InstrumentButtonStyle: ButtonStyle {
    var selected = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(selected ? Theme.screenInk : Theme.text)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: selected
                        ? [Color(hex: 0x414a38), Color(hex: 0x252e20)]
                        : [Theme.keyTop, Theme.keyBottom], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.keyEdge, lineWidth: 1))
                    .overlay(alignment: .top) { Theme.highlight.opacity(0.65).frame(height: 1).padding(.horizontal, 3) }
                    .shadow(color: Theme.skirt, radius: 0, y: configuration.isPressed || selected ? 1 : 3)
            }
            .offset(y: configuration.isPressed ? 2 : 0)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}

/// HSL (CSS-style) → UIColor. The color math in Core is HSL to match the web
/// build; UIKit wants HSB.
extension UIColor {
    convenience init(_ hsl: HSL, alpha: CGFloat = 1) {
        let h = (hsl.h.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360) / 360
        let s = min(max(hsl.s / 100, 0), 1)
        let l = min(max(hsl.l / 100, 0), 1)
        let v = l + s * min(l, 1 - l)
        let sv = v == 0 ? 0 : 2 * (1 - l / v)
        self.init(hue: h, saturation: sv, brightness: v, alpha: alpha)
    }
}

extension Store {
    /// SwiftUI two-way binding onto a state leaf, emitting web-style paths.
    func binding<T: Equatable>(_ keyPath: WritableKeyPath<AppState, T>) -> Binding<T> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.set(keyPath, $0) }
        )
    }
}

/// Keep input tracking and the audio/MIDI router in agreement after Panic.
extension Notification.Name {
    static let instrumentPanic = Notification.Name("expressionpad.instrumentPanic")
}
extension Router {
    func panic() {
        allOff()
        NotificationCenter.default.post(name: .instrumentPanic, object: self)
    }
}
