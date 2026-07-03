/// The playing surface: a UIKit view (SwiftUI gestures can't do independent
/// multi-touch) rendering with CoreGraphics and pumping a CADisplayLink only
/// while touches are live or the ripple field still has energy — the port of
/// pad.ts. Hardware keyboards drive the kbd-* layouts via pressesBegan.
import SwiftUI
import UIKit
import ExpressionPadCore

struct PadView: UIViewRepresentable {
    let store: Store
    let router: Router

    func makeUIView(context: Context) -> PadSurfaceView {
        PadSurfaceView(store: store, sink: router)
    }

    func updateUIView(_ uiView: PadSurfaceView, context: Context) {}
}

final class PadSurfaceView: UIView {
    private let store: Store
    private var layout: ExpressionPadCore.Layout
    private var field: BrightnessField
    private(set) var tracker: TouchTracker!
    private var keyboard: KeyboardInput!

    private var displayLink: CADisplayLink?
    private var lastFrame = CACurrentMediaTime()
    private var touchIds: [UITouch: Int] = [:]
    private var nextTouchId = 1
    private var builtSize = CGSize.zero
    private var unsubscribe: (() -> Void)?

    init(store: Store, sink: VoiceSink) {
        self.store = store
        let params = PadSurfaceView.layoutParams(store, 1, 1)
        layout = buildLayout(params)
        field = BrightnessField(layout.keys)
        super.init(frame: .zero)

        isMultipleTouchEnabled = true
        backgroundColor = UIColor(Theme.padBg)
        contentMode = .redraw

        tracker = TouchTracker(
            getLayout: { [unowned self] in self.layout },
            getPad: { [unowned self] in self.store.state.pad },
            sink: sink,
            onChange: { [unowned self] in self.requestRender() },
            // Every note onset drops a "pebble" whose wave spreads across the
            // lattice — at event time, so even sub-frame taps make a splash.
            onTrigger: { [unowned self] key in
                if self.store.state.appearance.ripples { self.field.poke(key.id, 1.3) }
            }
        )
        keyboard = KeyboardInput(getLayout: { [unowned self] in self.layout }, tracker: tracker)

        unsubscribe = store.subscribe { [weak self] _, path in
            guard let self else { return }
            if path.hasPrefix("pad") || path.hasPrefix("appearance") {
                if path.hasPrefix("pad") && !path.contains("slide") { self.rebuild() }
                self.requestRender()
            }
        }

        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        link.isPaused = true
        displayLink = link
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        displayLink?.invalidate()
        unsubscribe?()
    }

    static func layoutParams(_ store: Store, _ width: Double, _ height: Double) -> LayoutParams {
        let pad = store.state.pad
        // Keyboard layouts have a fixed physical row count regardless of config.
        let rows = pad.layout.isKeyboard ? 4 : pad.rows
        return LayoutParams(
            kind: pad.layout,
            rows: rows,
            cols: pad.cols,
            width: width,
            height: height,
            baseNote: pad.baseNote,
            rowOffsets: rowOffsets(pad.rowTuning, rows),
            scale: SCALES[pad.colScale] ?? SCALES["Chromatic"]!
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Only a real size change forces a rebuild (which cancels live notes);
        // spurious layout passes must not cut a performance short.
        if bounds.size != builtSize && bounds.width > 0 && bounds.height > 0 {
            rebuild()
            requestRender()
        }
    }

    private func rebuild() {
        tracker.cancelAll()
        touchIds.removeAll()
        builtSize = bounds.size
        layout = buildLayout(PadSurfaceView.layoutParams(store, bounds.width, bounds.height))
        field = BrightnessField(layout.keys)
    }

    // ---------------------------------------------------------- animation ---

    private func requestRender() {
        setNeedsDisplay()
        displayLink?.isPaused = false
        lastFrame = CACurrentMediaTime()
    }

    @objc private func tick() {
        let now = CACurrentMediaTime()
        let dt = min(0.08, max(0, now - lastFrame))
        lastFrame = now
        field.step(dt)
        setNeedsDisplay()
        // Keep animating while touches are live or the field is still moving.
        if tracker.active.isEmpty && field.energy < 0.002 {
            displayLink?.isPaused = true
        }
    }

    // ------------------------------------------------------------ touches ---

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            nextTouchId += 1
            touchIds[t] = nextTouchId
            let p = t.location(in: self)
            tracker.down(nextTouchId, p.x, p.y)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            // Ids exist only for touches that began here (rebuild drops them).
            guard let tid = touchIds[t] else { continue }
            // Coalesced touches keep 120 Hz glides smooth on ProMotion.
            for c in event?.coalescedTouches(for: t) ?? [t] {
                let p = c.location(in: self)
                tracker.move(tid, p.x, p.y)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouches(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouches(touches)
    }

    private func endTouches(_ touches: Set<UITouch>) {
        for t in touches {
            if let tid = touchIds.removeValue(forKey: t) { tracker.up(tid) }
        }
    }

    // ------------------------------------------------- hardware keyboard ---

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { becomeFirstResponder() }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            if let code = press.key.flatMap({ keyCodeName($0.keyCode) }) {
                keyboard.keyDown(code)
                handled = true
            }
        }
        if !handled { super.pressesBegan(presses, with: event) }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            if let code = press.key.flatMap({ keyCodeName($0.keyCode) }) {
                keyboard.keyUp(code)
                handled = true
            }
        }
        if !handled { super.pressesEnded(presses, with: event) }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        keyboard.releaseAll()
        super.pressesCancelled(presses, with: event)
    }

    // ------------------------------------------------------------ drawing ---

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let app = store.state.appearance

        ctx.setFillColor(UIColor(Theme.padBg).cgColor)
        ctx.fill(bounds)

        var activeKeyIds: [Int: Double] = [:] // key id → pressure
        for t in tracker.active.values {
            activeKeyIds[t.key.id] = max(activeKeyIds[t.key.id] ?? 0, t.pressure)
        }

        let opts = ColorOpts(
            brightness: app.brightness,
            contrast: app.contrast,
            baseNote: store.state.pad.baseNote
        )
        let rippleGain = 7 * app.rippleAmount
        let labelFontName = "AvenirNextCondensed-Regular"

        // Whites under blacks: draw in array order (whites first per row).
        for key in layout.keys {
            let colors = keyColors(app.scheme, key, opts)
            let active = activeKeyIds[key.id] != nil
            var fill = colors.fill
            let f = Double(field.get(key.id))
            if !active && abs(f) > 0.008 {
                // Crests lighten toward white; troughs dip darker at reduced
                // gain so the rebound reads as a gentle dip, not a flicker.
                let amt = f >= 0
                    ? min(1, f * rippleGain)
                    : max(-0.18, f * rippleGain * 0.35)
                fill.l = max(3, min(94, fill.l + (90 - fill.l) * amt))
            }
            drawKey(ctx, key, fill: fill, stroke: colors.stroke,
                    active: active, pressure: activeKeyIds[key.id] ?? 0)

            if app.labels && (key.kind != .black || key.char != nil) {
                let labelColor = active
                    ? UIColor(Theme.padBg.opacity(1))
                    : UIColor(colors.label)
                let size = max(9, min(16, key.w * 0.22))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: labelFontName, size: size)
                        ?? UIFont.systemFont(ofSize: size),
                    .foregroundColor: labelColor,
                ]
                let text = noteName(key.note) as NSString
                let bounds = text.size(withAttributes: attrs)
                let labelY = key.kind == .white && key.char == nil
                    ? key.y + key.h * 0.78
                    : key.cy
                text.draw(
                    at: CGPoint(x: key.cx - bounds.width / 2, y: labelY - bounds.height / 2),
                    withAttributes: attrs
                )
            }
            if app.labels, let char = key.char {
                let size = max(8, key.w * 0.16)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: labelFontName, size: size)
                        ?? UIFont.systemFont(ofSize: size),
                    .foregroundColor: (active
                        ? UIColor(Theme.padBg.opacity(1))
                        : UIColor(colors.label)).withAlphaComponent(0.55),
                ]
                (char as NSString).draw(
                    at: CGPoint(x: key.x + key.w * 0.12, y: key.y + key.h * 0.1),
                    withAttributes: attrs
                )
            }
        }
    }

    private func drawKey(
        _ ctx: CGContext, _ key: KeyShape, fill: HSL, stroke: HSL,
        active: Bool, pressure: Double
    ) {
        ctx.saveGState()
        if active {
            ctx.setShadow(
                offset: .zero,
                blur: 18 + pressure * 22,
                color: UIColor(white: 1, alpha: 0.95).cgColor
            )
        }
        let fillColor = active
            ? UIColor(white: (86 + pressure * 12) / 100, alpha: 1)
            : UIColor(fill)
        let strokeColor = active ? UIColor.white : UIColor(stroke)
        ctx.setFillColor(fillColor.cgColor)
        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(active ? 2 : 1)

        let path: UIBezierPath
        if let poly = key.poly, poly.count >= 3 {
            path = UIBezierPath()
            path.move(to: CGPoint(x: poly[0].x, y: poly[0].y))
            for p in poly.dropFirst() { path.addLine(to: CGPoint(x: p.x, y: p.y)) }
            path.close()
        } else {
            let inset = key.inset ?? (key.kind == .black ? 1 : 1.5)
            let r = min(6, key.w * 0.08)
            path = UIBezierPath(
                roundedRect: CGRect(
                    x: key.x + inset, y: key.y + inset,
                    width: key.w - inset * 2, height: key.h - inset * 2
                ),
                cornerRadius: r
            )
        }
        ctx.addPath(path.cgPath)
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()
    }
}

/// UIKeyboardHIDUsage → KeyboardEvent.code names used by the kbd layouts.
func keyCodeName(_ code: UIKeyboardHIDUsage) -> String? {
    switch code {
    case .keyboardA: return "KeyA"
    case .keyboardB: return "KeyB"
    case .keyboardC: return "KeyC"
    case .keyboardD: return "KeyD"
    case .keyboardE: return "KeyE"
    case .keyboardF: return "KeyF"
    case .keyboardG: return "KeyG"
    case .keyboardH: return "KeyH"
    case .keyboardI: return "KeyI"
    case .keyboardJ: return "KeyJ"
    case .keyboardK: return "KeyK"
    case .keyboardL: return "KeyL"
    case .keyboardM: return "KeyM"
    case .keyboardN: return "KeyN"
    case .keyboardO: return "KeyO"
    case .keyboardP: return "KeyP"
    case .keyboardQ: return "KeyQ"
    case .keyboardR: return "KeyR"
    case .keyboardS: return "KeyS"
    case .keyboardT: return "KeyT"
    case .keyboardU: return "KeyU"
    case .keyboardV: return "KeyV"
    case .keyboardW: return "KeyW"
    case .keyboardX: return "KeyX"
    case .keyboardY: return "KeyY"
    case .keyboardZ: return "KeyZ"
    case .keyboard1: return "Digit1"
    case .keyboard2: return "Digit2"
    case .keyboard3: return "Digit3"
    case .keyboard4: return "Digit4"
    case .keyboard5: return "Digit5"
    case .keyboard6: return "Digit6"
    case .keyboard7: return "Digit7"
    case .keyboard8: return "Digit8"
    case .keyboard9: return "Digit9"
    case .keyboard0: return "Digit0"
    case .keyboardHyphen: return "Minus"
    case .keyboardEqualSign: return "Equal"
    case .keyboardOpenBracket: return "BracketLeft"
    case .keyboardCloseBracket: return "BracketRight"
    case .keyboardSemicolon: return "Semicolon"
    case .keyboardQuote: return "Quote"
    case .keyboardComma: return "Comma"
    case .keyboardPeriod: return "Period"
    case .keyboardSlash: return "Slash"
    default: return nil
    }
}
