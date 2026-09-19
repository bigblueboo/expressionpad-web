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


struct Knob: View {
    @Binding var value: Double
    var label: String
    var min: Double = 0
    var max: Double = 1
    var fmt: ((Double) -> String)?
    @State private var dragStart: Double?
    @State private var initial: Double?
    private var t: Double { (value - min) / (max - min) }

    var body: some View {
        Widget(label: label) {
            VStack(spacing: 7) {
                ZStack {
                    Circle().fill(Color(hex: 0x30372b))
                        .shadow(color: .black.opacity(0.35), radius: 1, y: 3)
                    Circle().stroke(Color(hex: 0x929e80), style: StrokeStyle(lineWidth: 2, dash: [1, 1.8])).padding(1)
                    Circle().fill(LinearGradient(colors: [Color(hex: 0x666e59), Color(hex: 0x38422e)], startPoint: .topLeading, endPoint: .bottomTrailing)).padding(4)
                    Capsule().fill(Color(hex: 0xf4d5aa)).frame(width: 3, height: 11)
                        .offset(y: -11).rotationEffect(.degrees(-135 + t * 270))
                }.frame(width: 40, height: 40).frame(minWidth: 44, minHeight: 44)
                Text((fmt ?? percentFmt(min, max))(value)).font(Theme.mono(11)).foregroundStyle(Theme.textDim)
            }
            .contentShape(Rectangle())
            .onAppear { if initial == nil { initial = value } }
            .gesture(DragGesture(minimumDistance: 4).onChanged { g in
                if dragStart == nil { dragStart = value }
                value = clamp((dragStart ?? value) - Double(g.translation.height) / 150 * (max - min), min, max)
            }.onEnded { _ in dragStart = nil })
            .onTapGesture(count: 2) { if let initial { value = initial } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue((fmt ?? percentFmt(min, max))(value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = clamp(value + (max - min) / 100, min, max)
            case .decrement: value = clamp(value - (max - min) / 100, min, max)
            @unknown default: break
            }
        }
    }
}

struct ToggleSquare: View {
    @Binding var isOn: Bool
    var label: String
    var body: some View {
        Widget(label: label) {
            Button { isOn.toggle() } label: {
                RoundedRectangle(cornerRadius: 1).fill(isOn ? Theme.accent : Theme.accentDim)
                    .frame(width: 16, height: isOn ? 7 : 4).frame(width: 44, height: 44)
            }
            .buttonStyle(InstrumentButtonStyle(selected: isOn))
            .accessibilityLabel(label).accessibilityValue(isOn ? "On" : "Off")
        }
    }
}

struct SelectMenu<T: Hashable>: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Binding var selection: T
    var label: String
    var options: [(value: T, text: String)]
    var body: some View {
        Widget(label: label) {
            Menu {
                Picker(label, selection: $selection) {
                    ForEach(options, id: \.value) { option in Text(option.text).tag(option.value) }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(options.first { $0.value == selection }?.text ?? "—").lineLimit(typeSize.isAccessibilitySize ? nil : 2).fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                }
                .font(Theme.font(12)).foregroundStyle(Theme.screenInk)
                .padding(.horizontal, 10).frame(minHeight: 44).frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 170)
                .background(Theme.widgetBg, in: RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Theme.keyEdge, lineWidth: 1))
            }
            .accessibilityLabel(label)
            .accessibilityValue(options.first { $0.value == selection }?.text ?? "")
        }
    }
}
extension SelectMenu where T == String {
    init(selection: Binding<String>, label: String, options: [String]) {
        self.init(selection: selection, label: label, options: options.map { ($0, $0) })
    }
}

struct StepperControl: View {
    @Binding var value: Int
    var label: String
    var min: Int
    var max: Int
    var fmt: ((Int) -> String)?
    var body: some View {
        Widget(label: label) {
            HStack(spacing: 0) {
                stepButton(increment: false)
                Text((fmt ?? { String($0) })(value)).font(Theme.mono(11)).foregroundStyle(Theme.screenInk)
                    .frame(minWidth: 32, minHeight: 32).background(Theme.widgetBg)
                stepButton(increment: true)
            }
        }
    }
    private func stepButton(increment: Bool) -> some View {
        Button { value = clamp(value + (increment ? 1 : -1), min, max) } label: {
            Image(systemName: increment ? "plus" : "minus").font(.system(size: 16, weight: .regular)).frame(width: 44, height: 44)
        }.buttonStyle(InstrumentButtonStyle())
            .disabled(increment ? value >= max : value <= min)
            .opacity((increment ? value >= max : value <= min) ? 0.45 : 1)
            .accessibilityLabel("\(increment ? "Increase" : "Decrease") \(label)")
            .accessibilityValue((fmt ?? { String($0) })(value))
    }
}

struct ActionButton: View {
    var label: String
    var action: () -> Void
    var body: some View {
        Widget(label: label) {
            Button(action: action) {
                Text(label.uppercased()).font(Theme.fontMedium(11)).tracking(0.6)
                    .padding(.horizontal, 13).frame(minHeight: 44)
            }.buttonStyle(InstrumentButtonStyle()).accessibilityLabel(label)
        }
    }
}

struct Widget<Content: View>: View {
    var label: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 7) {
            content
            Text(label.uppercased()).font(Theme.font(10)).tracking(0.7)
                .foregroundStyle(Theme.textDim).lineLimit(2).multilineTextAlignment(.center)
                .accessibilityHidden(true)
        }.frame(minWidth: 44)
    }
}

struct PanelGroup<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(Theme.fontMedium(11)).tracking(1.1).foregroundStyle(Theme.textDim)
                .accessibilityAddTraits(.isHeader)
            FlowLayout(spacing: 14) { content }
        }
        .frame(maxWidth: 350, alignment: .leading)
        .padding(.horizontal, 4).padding(.vertical, 14)
        .overlay(alignment: .top) { Theme.line.frame(height: 1) }
        .id(title)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
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
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Item {
        var index: Int
        var size: CGSize
    }

    private struct Row {
        var items: [Item] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(_ maxWidth: CGFloat, _ subviews: LayoutSubviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for (index, view) in subviews.enumerated() {
            // A child can wrap and become taller once constrained (notably a
            // PanelGroup's own flow). Measure it with the width it will
            // actually receive; measuring only `.unspecified` makes the outer
            // layout reserve the child's single-row height and causes overlap.
            let natural = view.sizeThatFits(.unspecified)
            let childWidth = min(natural.width, maxWidth)
            let size = view.sizeThatFits(
                ProposedViewSize(width: childWidth, height: nil)
            )
            let needed = current.width + (current.width > 0 ? spacing : 0) + size.width
            if !current.items.isEmpty && needed > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.width += (current.width > 0 ? spacing : 0) + size.width
            current.height = max(current.height, size.height)
            current.items.append(Item(index: index, size: size))
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}
