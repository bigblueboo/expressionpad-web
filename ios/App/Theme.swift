/// The web build's style.css palette, ported.
import SwiftUI
import ExpressionPadCore

enum Theme {
    static let bg = Color(hex: 0x0a0e14)
    static let padBg = Color(hex: 0x06080c)
    static let topbarBg = Color(hex: 0x0b1018)
    static let panelBg = Color(red: 13 / 255, green: 24 / 255, blue: 38 / 255).opacity(0.92)
    static let groupBg = Color(red: 10 / 255, green: 18 / 255, blue: 28 / 255).opacity(0.6)
    static let groupTitleBg = Color(hex: 0x0d1826)
    static let line = Color(hex: 0x1f3a52)
    static let accent = Color(hex: 0x57c7ff)
    static let accentDim = Color(hex: 0x2a6e96)
    static let text = Color(hex: 0xcfe6f5)
    static let textDim = Color(hex: 0x6f93ab)
    static let widgetBg = Color(hex: 0x0c1722)

    static func font(_ size: CGFloat) -> Font {
        .custom("AvenirNextCondensed-Regular", size: size, relativeTo: .body)
    }

    static func fontMedium(_ size: CGFloat) -> Font {
        .custom("AvenirNextCondensed-Medium", size: size, relativeTo: .body)
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
