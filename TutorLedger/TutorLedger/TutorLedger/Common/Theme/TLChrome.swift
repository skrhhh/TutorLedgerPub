import SwiftUI

// MARK: - Tab

enum TLTab: Int, CaseIterable, Identifiable {
    case home
    case students
    case bills
    case stats
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: String(localized: "首页")
        case .students: String(localized: "学生")
        case .bills: String(localized: "账单")
        case .stats: String(localized: "统计")
        case .settings: String(localized: "设置")
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .students: "person.2.fill"
        case .bills: "doc.text.fill"
        case .stats: "chart.bar.fill"
        case .settings: "gearshape.fill"
        }
    }
}

struct TLCustomTabBar: View {
    @Binding var selected: TLTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TLTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selected == tab ? .semibold : .regular))
                            .symbolEffect(.bounce, value: selected == tab)
                        Text(tab.title)
                            .font(.system(size: 10, weight: selected == tab ? .semibold : .regular))
                    }
                    .foregroundStyle(selected == tab ? TLColors.tealDark : TLColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selected == tab {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            TLColors.tealLight.opacity(0.45),
                                            TLColors.cyan.opacity(0.25)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            Color(red: 0.94, green: 0.99, blue: 0.98).opacity(0.88)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .background(.ultraThinMaterial)
                .shadow(color: TLColors.teal.opacity(0.14), radius: 24, y: 10)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [TLColors.tealLight.opacity(0.5), TLColors.cyan.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Top Bar

struct TLTopBar: View {
    let title: String
    var subtitle: String?
    var showBack: Bool = false
    var leadingTitle: String?
    var trailingIcon: String?
    var trailingTitle: String?
    var trailingEnabled: Bool = true
    var onLeading: (() -> Void)?
    var onTrailing: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if showBack || onLeading != nil {
                Button {
                    if let onLeading { onLeading() } else { dismiss() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        if let leadingTitle {
                            Text(LocalizedStringKey(leadingTitle))
                                .font(.subheadline)
                        }
                    }
                    .foregroundStyle(TLColors.accentGradient)
                    .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(TLColors.accentGradient)
                    .frame(width: 4, height: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(TLColors.primaryText)
                if let subtitle {
                    Text(LocalizedStringKey(subtitle))
                        .font(.caption)
                        .foregroundStyle(TLColors.secondaryText)
                }
            }

            Spacer(minLength: 0)

            if let trailingIcon, let onTrailing {
                Button(action: onTrailing) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(TLColors.accentGradient)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            } else if let trailingTitle, let onTrailing {
                Button(action: onTrailing) {
                    Text(LocalizedStringKey(trailingTitle))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            trailingEnabled
                                ? AnyShapeStyle(TLColors.accentGradient)
                                : AnyShapeStyle(TLColors.secondaryText.opacity(0.45))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Page Scaffold

struct TLPageScaffold<Content: View>: View {
    let title: String
    var subtitle: String?
    var showBack: Bool = false
    var leadingTitle: String?
    var trailingIcon: String?
    var trailingTitle: String?
    var trailingEnabled: Bool = true
    var onLeading: (() -> Void)?
    var onTrailing: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            TLTopBar(
                title: title,
                subtitle: subtitle,
                showBack: showBack,
                leadingTitle: leadingTitle,
                trailingIcon: trailingIcon,
                trailingTitle: trailingTitle,
                trailingEnabled: trailingEnabled,
                onLeading: onLeading,
                onTrailing: onTrailing
            )
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .tlScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    KeyboardDismiss.dismiss()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(TLColors.teal)
            }
        }
        .installKeyboardDismissOnTap()
    }
}

// MARK: - Form Components

struct TLFormCard<Content: View>: View {
    let title: String
    var icon: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TLSectionHeader(title: String(localized: String.LocalizationValue(title)), icon: icon)
            content()
        }
        .tlCard()
    }
}

struct TLFormRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(label))
                .font(.caption.weight(.medium))
                .foregroundStyle(TLColors.secondaryText)
            content()
        }
    }
}

struct TLTextInput: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField("", text: $text, prompt: Text(LocalizedStringKey(placeholder)))
            .keyboardType(keyboard)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(TLColors.softFillGradient)
            }
            .foregroundStyle(TLColors.primaryText)
    }
}

struct TLDetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = TLColors.primaryText

    var body: some View {
        HStack {
            Text(LocalizedStringKey(label))
                .font(.subheadline)
                .foregroundStyle(TLColors.secondaryText)
            Spacer()
            Text(LocalizedStringKey(value))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

struct TLMoneyHero: View {
    let amount: String
    var label: String = String(localized: "合计")
    var gradient: LinearGradient = TLColors.incomeGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(label))
                .font(.caption)
                .foregroundStyle(TLColors.secondaryText)
            Text(amount)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(gradient)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
                .accessibilityLabel("\(label) \(amount)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TLChipSelector<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let title: (Item) -> String

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    Text(title(item))
                        .font(.subheadline.weight(selection == item ? .semibold : .regular))
                        .foregroundStyle(selection == item ? .white : TLColors.secondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            if selection == item {
                                TLColors.breezeGradient
                            } else {
                                TLColors.softFillGradient
                            }
                        }
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Simple flow layout for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var positions: [CGPoint] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

struct TLSettingsRow: View {
    let icon: String
    let title: String
    var value: String?
    var tint: Color = TLColors.teal
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                TLIconBadge(icon: icon, color: tint, size: 36)
                Text(LocalizedStringKey(title))
                    .font(.subheadline)
                    .foregroundStyle(TLColors.primaryText)
                Spacer()
                if let value {
                    Text(LocalizedStringKey(value))
                        .font(.subheadline)
                        .foregroundStyle(TLColors.secondaryText)
                }
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLColors.secondaryText)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct TLBarChart: View {
    let values: [CGFloat]
    let labels: [String]
    var tint: Color = TLColors.teal

    var body: some View {
        let maxVal = max(values.max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.9), tint.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: max(8, 80 * value / maxVal))
                    Text(labels[index])
                        .font(.system(size: 9))
                        .foregroundStyle(TLColors.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 100)
    }
}

struct TLMarkPaidSheet: View {
    @Binding var paymentMethod: PaymentMethod
    @Binding var paidAt: Date
    let confirmTitle: String
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    init(
        paymentMethod: Binding<PaymentMethod>,
        paidAt: Binding<Date>,
        confirmTitle: String = String(localized: "确认收款"),
        onConfirm: @escaping () -> Void
    ) {
        _paymentMethod = paymentMethod
        _paidAt = paidAt
        self.confirmTitle = confirmTitle
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(spacing: 0) {
            TLTopBar(title: String(localized: "确认收款"), showBack: true, onLeading: { dismiss() })
            ScrollView {
                VStack(spacing: 16) {
                    TLFormCard(title: String(localized: "收款信息"), icon: "yensign.circle") {
                        TLFormRow(label: String(localized: "收款方式")) {
                            TLChipSelector(
                                items: Array(PaymentMethod.allCases),
                                selection: $paymentMethod,
                                title: \.title
                            )
                        }
                        TLFormRow(label: String(localized: "收款日期")) {
                            DatePicker("", selection: $paidAt, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .tint(TLColors.teal)
                        }
                    }
                    Button(confirmTitle) {
                        onConfirm()
                        dismiss()
                    }
                    .buttonStyle(TLPrimaryButtonStyle())
                }
                .padding(20)
            }
        }
        .tlScreenBackground()
        .presentationDetents([.medium])
        .installKeyboardDismissOnTap()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") { KeyboardDismiss.dismiss() }
                    .foregroundStyle(TLColors.teal)
            }
        }
    }
}

// MARK: - Toast

struct TLToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background {
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(0.82))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: message)
            .onChange(of: message) { _, newValue in
                guard newValue != nil else { return }
                let current = newValue
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                    if message == current {
                        message = nil
                    }
                }
            }
    }
}

extension View {
    func tlToast(_ message: Binding<String?>) -> some View {
        modifier(TLToastModifier(message: message))
    }
}
