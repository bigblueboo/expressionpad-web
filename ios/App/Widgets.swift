/// SwiftUI control widgets — knob, toggle, select, stepper, action button,
/// group box — styled after the web build's widgets.ts + style.css.
import SwiftUI
import ExpressionPadCore

func percentFmt(_ min: Double, _ max: Double) -> (Double) -> String {
    { v in "\(Int((((v - min) / (max - min)) * 100).rounded()))%" }
}

let secFmt: (Double) -> String = { v in
    v < 1 ? "\(Int((v * 1000).rounded()))ms" : String(format: "%.1fs", v)
}

let semiFmt: (Int) -> String = { v in v > 0 ? "+\(v)" : String(v) }

// ------------------------------------------------------------------ knob ---

struct Knob: View {
    @Binding var value: Double
    var label: String
    var min: Double = 0
    var max: Double = 1
    var fmt: ((Double) -> String)?

    @State private var dragStart: (y: CGFloat, v: Double)?
    @State private var initial: Double?

    private var t: Double { (value - min) / (max - min) }

    var body: some View {
        Widget(label: label) {
            VStack(spacing: 1) {
                dial
                Text((fmt ?? percentFmt(min, max))(value))
                    .font(Theme.font(9))
                    .foregroundColor(Theme.accent)
            }
            .onAppear { if initial == nil { initial = value } }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if dragStart == nil { dragStart = (g.startLocation.y, value) }
                        guard let start = dragStart else { return }
                        let dv = Double(start.y - g.location.y) / 150 * (max - min)
                        value = clamp(start.v + dv, min, max)
                    }
                    .onEnded { _ in dragStart = nil }
            )
            .onTapGesture(count: 2) {
                if let initial { value = initial }
            }
        }
        .accessibilityLabel(label)
        .accessibilityValue((fmt ?? percentFmt(min, max))(value))
    }

    private var dial: some View {
        ZStack {
            Circle()
                .fill(Theme.widgetBg)
            Circle()
                .stroke(Theme.accentDim, lineWidth: 2)
            // Cyan arc sweep from -135°.
            Circle()
                .trim(from: 0, to: CGFloat(t) * 0.75)
                .rotation(.degrees(135))
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .padding(1.5)
            // Pointer.
            Capsule()
                .fill(Theme.text)
                .frame(width: 2, height: 9)
                .offset(y: -10)
                .rotationEffect(.degrees(-135 + t * 270))
        }
        .frame(width: 32, height: 32)
        .contentShape(Rectangle())
    }
}

// ---------------------------------------------------------------- toggle ---

struct ToggleSquare: View {
    @Binding var isOn: Bool
    var label: String

    var body: some View {
        Widget(label: label) {
            Button {
                isOn.toggle()
            } label: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isOn ? Theme.accent : Theme.widgetBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isOn ? Theme.accent : Theme.accentDim, lineWidth: 1.5)
                    )
                    .frame(width: 34, height: 30)
                    .shadow(color: isOn ? Theme.accent.opacity(0.55) : .clear, radius: 8)
            }
            .buttonStyle(.plain)
        }
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "on" : "off")
    }
}

// ---------------------------------------------------------------- select ---

struct SelectMenu<T: Hashable>: View {
    @Binding var selection: T
    var label: String
    var options: [(value: T, text: String)]

    var body: some View {
        Widget(label: label) {
            Menu {
                ForEach(options, id: \.value) { option in
                    Button {
                        selection = option.value
                    } label: {
                        if option.value == selection {
                            Label(option.text, systemImage: "checkmark")
                        } else {
                            Text(option.text)
                        }
                    }
                }
            } label: {
                Text(options.first { $0.value == selection }?.text ?? "—")
                    .font(Theme.font(12))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: 120)
                    .background(Theme.widgetBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Theme.accentDim, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .accessibilityLabel(label)
    }
}

extension SelectMenu where T == String {
    init(selection: Binding<String>, label: String, options: [String]) {
        self.init(
            selection: selection, label: label,
            options: options.map { (value: $0, text: $0) }
        )
    }
}

// --------------------------------------------------------------- stepper ---

struct StepperControl: View {
    @Binding var value: Int
    var label: String
    var min: Int
    var max: Int
    var fmt: ((Int) -> String)?

    var body: some View {
        Widget(label: label) {
            HStack(spacing: 2) {
                stepButton("−") { value = Swift.max(min, value - 1) }
                Text((fmt ?? { String($0) })(value))
                    .font(Theme.font(12))
                    .foregroundColor(Theme.text)
                    .frame(minWidth: 34)
                stepButton("+") { value = Swift.min(max, value + 1) }
            }
        }
        .accessibilityLabel(label)
        .accessibilityValue((fmt ?? { String($0) })(value))
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(Theme.font(15))
                .foregroundColor(Theme.accent)
                .frame(width: 26, height: 28)
                .background(Theme.widgetBg)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.accentDim, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}

// ---------------------------------------------------------------- action ---

struct ActionButton: View {
    var label: String
    var action: () -> Void

    var body: some View {
        Widget(label: label) {
            Button(action: action) {
                Text(label.uppercased())
                    .font(Theme.font(11))
                    .tracking(1.3)
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(Theme.widgetBg)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.accentDim, lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
    }
}

// ------------------------------------------------------- widget skeleton ---

/// Control + tiny tracking-wide caps label underneath, like .widget.
struct Widget<Content: View>: View {
    var label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 3) {
            content
            Text(label.uppercased())
                .font(Theme.font(9))
                .tracking(1.2)
                .foregroundColor(Theme.textDim)
                .lineLimit(1)
        }
        .frame(minWidth: 44)
    }
}

// ----------------------------------------------------------------- group ---

/// A titled group box, like the original's PADMATRIX / REVERB frames.
struct PanelGroup<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            content
        }
        .padding(.init(top: 12, leading: 8, bottom: 6, trailing: 8))
        .background(Theme.groupBg)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .topLeading) {
            Text(title)
                .font(Theme.font(10))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 6)
                .background(Theme.groupTitleBg)
                .offset(x: 8, y: -7)
        }
        .padding(.top, 7)
    }
}

// ------------------------------------------------------------ flow layout ---

/// Wrapping row of group boxes, like the panel's flex-wrap.
struct Flow<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: Content

    var body: some View {
        let layout = FlowLayout(spacing: spacing)
        layout { content }
    }
}

struct FlowLayout: SwiftUI.Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal.width ?? .infinity, subviews)
        var height: CGFloat = 0
        var width: CGFloat = 0
        for row in rows {
            height += row.height + (height > 0 ? spacing : 0)
            width = max(width, row.width)
        }
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        let rows = computeRows(bounds.width, subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indexes {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indexes: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(_ maxWidth: CGFloat, _ subviews: LayoutSubviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for (index, view) in subviews.enumerated() {
            let size = view.sizeThatFits(.unspecified)
            let needed = current.width + (current.width > 0 ? spacing : 0) + size.width
            if !current.indexes.isEmpty && needed > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.width += (current.width > 0 ? spacing : 0) + size.width
            current.height = max(current.height, size.height)
            current.indexes.append(index)
        }
        if !current.indexes.isEmpty { rows.append(current) }
        return rows
    }
}
