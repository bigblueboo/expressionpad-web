/// The playing surface: a UIKit view (SwiftUI gestures can't do independent
/// multi-touch) rendering with CoreGraphics and pumping a CADisplayLink only
/// while vibrato is settling or the ripple field still has energy — the port of
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

    func updateUIView(_ uiView: PadSurfaceView, context: Context) { uiView.setNeedsDisplay(); uiView.setNeedsLayout() }
    static func dismantleUIView(_ uiView: PadSurfaceView, coordinator: ()) { uiView.silence() }
}

final class PadSurfaceView: UIView {
    /// Pad paths whose change alters key geometry and forces a layout rebuild.
    private static let geometryPaths: Set<String> = [
        "pad.layout", "pad.rows", "pad.cols", "pad.rowTuning", "pad.colScale",
        "pad.baseNote", "pad.mirror", "pad.mirrorOffset",
    ]

    private let store: Store
    private var layout: ExpressionPadCore.Layout
    private var field: BrightnessField
    private(set) var tracker: TouchTracker!
    private var keyboard: KeyboardInput!
    private let haptics = UIImpactFeedbackGenerator(style: .light)
    private var lastHaptic: CFTimeInterval = 0

    private var displayLink: CADisplayLink?
    private var displayLinkProxy: PadDisplayLinkProxy?
    private var lastFrame = CACurrentMediaTime()
    private var touchIds: [UITouch: Int] = [:]
    private var nextTouchId = 1
    private var builtSize = CGSize.zero
    private var unsubscribe: (() -> Void)?
    private var accessibilityNoteId = 3_000_000
    private var touchOffsets: [Int: CGPoint] = [:]
    private var builtOrigin = CGPoint.zero
    private static let pixelTexture = UIGraphicsImageRenderer(size: CGSize(width: 3, height: 3)).image { renderer in
        UIColor.black.withAlphaComponent(0.045).setFill()
        renderer.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
    }

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
                if self.store.state.appearance.ripples && !UIAccessibility.isReduceMotionEnabled { self.field.poke(key.id, 1.3) }
            },
            onFret: { [unowned self] in self.hapticTick() }
        )
        keyboard = KeyboardInput(getLayout: { [unowned self] in self.layout }, tracker: tracker)

        unsubscribe = store.subscribe { [weak self] _, path in
            guard let self else { return }
            if path.hasPrefix("pad") || path.hasPrefix("appearance") {
                // Only geometry changes rebuild (and thus cancel held touches);
                // expression changes update held voices without interrupting them.
                if Self.geometryPaths.contains(path) { self.rebuild() }
                else if ["pad.aftertouch", "pad.vibrato", "pad.slide", "pad.frets"].contains(path) { self.tracker.reconcileExpression() }
                if !self.store.state.appearance.ripples { self.field = BrightnessField(self.layout.keys) }
                self.requestRender()
            }
        }

        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]) { (view: PadSurfaceView, _: UITraitCollection) in
            view.requestRender()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(motionPreferenceChanged), name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(silence), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(silence), name: .instrumentPanic, object: sink)
        let proxy = PadDisplayLinkProxy(view: self)
        let link = CADisplayLink(target: proxy, selector: #selector(PadDisplayLinkProxy.tick))
        link.preferredFrameRateRange = CAFrameRateRange(
            minimum: 60, maximum: 120, preferred: 120
        )
        link.add(to: .main, forMode: .common)
        link.isPaused = true
        displayLinkProxy = proxy
        displayLink = link
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        displayLink?.invalidate()
        unsubscribe?()
        NotificationCenter.default.removeObserver(self)
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
            scale: SCALES[pad.colScale] ?? SCALES["Chromatic"]!,
            mirror: pad.mirror,
            mirrorOffset: pad.mirrorOffset
        )
    }

    /// Short haptic tick on fret crossings, scaled by the HAPTIC knob.
    private func hapticTick() {
        let amt = store.state.pad.haptics
        guard amt > 0 else { return }
        let now = CACurrentMediaTime()
        guard now - lastHaptic >= 0.04 else { return }
        lastHaptic = now
        haptics.impactOccurred(intensity: 0.3 + 0.7 * amt)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        let origin = convert(CGPoint.zero, to: window)
        if bounds.size != builtSize {
            let previous = layout
            builtSize = bounds.size
            layout = buildLayout(Self.layoutParams(store, bounds.width, bounds.height))
            tracker.reflow(from: previous)
            field = BrightnessField(layout.keys)
            rebuildAccessibilityElements()
            requestRender()
        }
        if origin != builtOrigin || !touchIds.isEmpty {
            for (touch, id) in touchIds {
                guard let active = tracker.active[id] else { continue }
                let raw = touch.location(in: self)
                touchOffsets[id] = CGPoint(x: active.x - raw.x, y: active.y - raw.y)
            }
            builtOrigin = origin
        }
    }

    private func rebuild() {
        silence()
        builtSize = bounds.size
        layout = buildLayout(Self.layoutParams(store, max(1, bounds.width), max(1, bounds.height)))
        field = BrightnessField(layout.keys)
        rebuildAccessibilityElements()
    }

    @objc func silence() {
        keyboard?.releaseAll()
        tracker.cancelAll()
        touchIds.removeAll()
        touchOffsets.removeAll()
        field = BrightnessField(layout.keys)
        displayLink?.isPaused = true
        setNeedsDisplay()
    }

    @objc private func motionPreferenceChanged() {
        field = BrightnessField(layout.keys)
        requestRender()
    }

    private func rebuildAccessibilityElements() {
        isAccessibilityElement = false
        let previous = accessibilityElements as? [PadKeyAccessibilityElement] ?? []
        accessibilityElements = layout.keys.enumerated().map { index, key in
            let element = index < previous.count ? previous[index] : PadKeyAccessibilityElement(accessibilityContainer: self)
            element.accessibilityLabel = "\(noteName(key.note, withOctave: true)), row \(key.row + 1), column \(key.col + 1)"
            element.accessibilityHint = "Double tap to play"
            element.accessibilityTraits = [.button, .playsSound]
            element.accessibilityFrameInContainerSpace = CGRect(
                x: key.x, y: key.y, width: key.w, height: key.h
            )
            element.activate = { [weak self] in
                guard let self else { return false }
                accessibilityNoteId += 1
                let id = accessibilityNoteId
                guard let current = layout.keys.first(where: { $0.id == key.id }) else { return false }
                tracker.down(id, current.cx, current.cy)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
                    self?.tracker.up(id)
                }
                return true
            }
            return element
        }
    }

    // ---------------------------------------------------------- animation ---

    private func requestRender() {
        setNeedsDisplay()
        // Touch input can arrive as a 120 Hz batch of coalesced samples. Do
        // not reset the simulation clock for every sample: doing so makes the
        // next display-link dt approach zero, visually stalling the wave while
        // new impulses accumulate. Reset only when waking a paused clock.
        if displayLink?.isPaused == true {
            lastFrame = CACurrentMediaTime()
            displayLink?.isPaused = false
        }
    }

    @objc fileprivate func tick() {
        let now = CACurrentMediaTime()
        let dt = min(0.08, max(0, now - lastFrame))
        lastFrame = now
        tracker.advance()
        field.step(dt)
        setNeedsDisplay()
        // Rest the display link when the LCD and vibrato spring have settled.
        if !tracker.needsAdvance && field.energy < 0.002 {
            displayLink?.isPaused = true
        }
    }

    // ------------------------------------------------------------ touches ---

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        becomeFirstResponder()
        // Keep the Taptic Engine warm so fret ticks land without latency.
        if store.state.pad.haptics > 0 { haptics.prepare() }
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
                let offset = touchOffsets[tid] ?? .zero
                tracker.move(tid, p.x + offset.x, p.y + offset.y)
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
            if let tid = touchIds.removeValue(forKey: t) { touchOffsets.removeValue(forKey: tid); tracker.up(tid) }
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
            if let key = press.key, !key.modifierFlags.intersection([.command, .control, .alternate]).isEmpty {
                super.pressesBegan([press], with: event)
                handled = true
                continue
            }
            if press.key?.keyCode == .keyboardEscape {
                keyboard.releaseAll()
                resignFirstResponder()
                handled = true
                continue
            }
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

        let dark = traitCollection.userInterfaceStyle == .dark
        let screen = app.scheme == "Studio"
            ? UIColor(HSL(h: 76, s: 19, l: dark ? 16 + app.brightness * 8 : 69 + (app.brightness - 0.65) * 24))
            : UIColor(white: dark ? 0.12 : 0.72, alpha: 1)
        ctx.setFillColor(screen.cgColor)
        ctx.fill(bounds)

        var activeKeyIds: [Int: Double] = [:] // key id → pressure
        for t in tracker.active.values {
            activeKeyIds[t.key.id] = max(activeKeyIds[t.key.id] ?? 0, t.pressure)
        }

        let opts = ColorOpts(
            brightness: app.brightness,
            contrast: app.contrast,
            baseNote: store.state.pad.baseNote, dark: dark
        )
        let rippleGain = 7 * app.rippleAmount
        let labelFontName = "IBMPlexMono-Regular"

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
            if active {
                let inverseLight = (dark && app.scheme == "Studio") || colors.fill.l < 35
                let pressure = activeKeyIds[key.id] ?? 0
                fill = HSL(h: fill.h, s: 22, l: inverseLight ? 86 - pressure * 4 : 16 + pressure * 6)
            }
            let ink = labelColor(fill)
            let isRoot = (key.note - store.state.pad.baseNote) % 12 == 0
            drawKey(ctx, key, fill: fill, stroke: colors.stroke, ink: ink, active: active, root: isRoot)

            if app.labels && (key.kind != .black || key.char != nil) {
                let labelColor = UIColor(ink)
                let size = max(9, min(16, key.w * 0.22))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: labelFontName, size: size)
                        ?? UIFont.systemFont(ofSize: size),
                    .foregroundColor: labelColor,
                ]
                let text = noteName(key.note, withOctave: isRoot) as NSString
                let bounds = text.size(withAttributes: attrs)
                let labelY = keyLabelY(key)
                text.draw(
                    at: CGPoint(x: key.cx - bounds.width / 2, y: labelY - bounds.height / 2),
                    withAttributes: attrs
                )
            }
            if app.labels, let char = key.char {
                let size = max(8, min(13, key.w * 0.16))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: labelFontName, size: size)
                        ?? UIFont.systemFont(ofSize: size),
                    .foregroundColor: UIColor(ink),
                ]
                (char as NSString).draw(
                    at: CGPoint(x: key.x + key.w * 0.12, y: key.y + key.h * 0.1),
                    withAttributes: attrs
                )
            }
        }

        // One pixel matrix and protective lens span the entire display.
        ctx.saveGState()
        ctx.setFillColor(UIColor(patternImage: Self.pixelTexture).cgColor)
        ctx.fill(bounds)
        ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.18).cgColor)
        ctx.setLineWidth(3)
        ctx.stroke(bounds.insetBy(dx: 0.5, dy: 0.5))
        ctx.restoreGState()

        // Mark the mirror seam so each thumb knows its half.
        if layout.mirrored {
            ctx.setStrokeColor(UIColor(HSL(h: 76, s: 19, l: dark ? 80 : 24)).cgColor)
            ctx.setLineDash(phase: 0, lengths: [4, 4])
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: bounds.midX, y: 0))
            ctx.addLine(to: CGPoint(x: bounds.midX, y: bounds.height))
            ctx.strokePath()
        }
    }

    private func keyInset(_ key: KeyShape) -> Double {
        max(key.inset ?? 0, min(3, min(key.w * 0.035, key.h * 0.045)))
    }

    private func keyLabelY(_ key: KeyShape) -> Double {
        guard key.kind == .white && key.char == nil else { return key.cy }
        return key.y + min(key.h * 0.78, key.h - keyInset(key) - 4 - min(16, key.h * 0.23))
    }

    private func drawKey(
        _ ctx: CGContext, _ key: KeyShape, fill: HSL, stroke: HSL,
        ink: HSL, active: Bool, root: Bool
    ) {
        ctx.saveGState()
        let gap = keyInset(key)
        let path: UIBezierPath
        if let poly = key.poly, poly.count >= 3 {
            path = UIBezierPath()
            let scale = max(0.1, 1 - gap * 2 / min(key.w, key.h))
            for (index, p) in poly.enumerated() {
                let point = CGPoint(x: key.cx + (p.x - key.cx) * scale, y: key.cy + (p.y - key.cy) * scale)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.close()
        } else {
            path = UIBezierPath(roundedRect: CGRect(x: key.x + gap, y: key.y + gap,
                width: max(0.1, key.w - gap * 2), height: max(0.1, key.h - gap * 2)), cornerRadius: 1)
        }
        ctx.setFillColor(UIColor(fill).cgColor)
        ctx.setStrokeColor(UIColor(stroke).cgColor)
        ctx.setLineWidth(traitCollection.accessibilityContrast == .high ? 1.5 : 0.75)
        ctx.addPath(path.cgPath)
        ctx.drawPath(using: .fillStroke)
        ctx.setFillColor(UIColor(ink).cgColor)
        let labelY = keyLabelY(key)
        if root {
            let width = min(20, key.w * 0.27)
            ctx.fill(CGRect(x: key.cx - width / 2, y: min(labelY + min(16, key.h * 0.23), key.y + key.h - gap - 4), width: width, height: 2))
        }
        if active {
            let size = max(2, min(4, min(key.w * 0.08, key.h * 0.08)))
            ctx.fill(CGRect(x: key.cx - size / 2, y: labelY - min(19, key.h * 0.27), width: size, height: size))
        }
        ctx.restoreGState()
    }

}

private final class PadDisplayLinkProxy: NSObject {
    weak var view: PadSurfaceView?

    init(view: PadSurfaceView) {
        self.view = view
    }

    @objc func tick() {
        view?.tick()
    }
}

private final class PadKeyAccessibilityElement: UIAccessibilityElement {
    var activate: (() -> Bool)?

    override func accessibilityActivate() -> Bool {
        activate?() ?? false
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
