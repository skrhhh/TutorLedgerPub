import SwiftUI

enum TLTheme {
    static let cardRadius: CGFloat = 18
    static let buttonRadius: CGFloat = 16
    static let chipRadius: CGFloat = 10
}

// MARK: - Card & Background

struct TLCardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: TLTheme.cardRadius, style: .continuous)
                    .fill(TLColors.cardGradient)
            }
            .clipShape(RoundedRectangle(cornerRadius: TLTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: TLTheme.cardRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [TLColors.tealLight.opacity(0.5), TLColors.cyan.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: TLColors.teal.opacity(0.08), radius: 16, y: 6)
    }
}

struct TLScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    TLColors.backgroundGradient
                        .ignoresSafeArea()

                    // 春风光晕
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [TLColors.cyan.opacity(0.18), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 180
                            )
                        )
                        .frame(width: 360, height: 360)
                        .offset(x: 120, y: -120)
                        .ignoresSafeArea()

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [TLColors.tealLight.opacity(0.14), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                        .offset(x: -100, y: 200)
                        .ignoresSafeArea()
                }
            }
    }
}

// MARK: - Buttons

struct TLPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: TLTheme.buttonRadius, style: .continuous)
                    .fill(
                        configuration.isPressed
                            ? LinearGradient(
                                colors: [
                                    Color(red: 0.25, green: 0.68, blue: 0.66),
                                    Color(red: 0.18, green: 0.58, blue: 0.60)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : TLColors.breezeGradient
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: TLTheme.buttonRadius, style: .continuous))
            .opacity(isEnabled ? 1 : 0.45)
            .shadow(color: TLColors.teal.opacity(isEnabled && !configuration.isPressed ? 0.32 : 0.08), radius: configuration.isPressed ? 6 : 14, y: configuration.isPressed ? 2 : 8)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct TLSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TLColors.tealDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: TLTheme.buttonRadius, style: .continuous)
                    .fill(TLColors.secondaryButtonGradient)
            }
            .overlay {
                RoundedRectangle(cornerRadius: TLTheme.buttonRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [TLColors.tealLight.opacity(0.6), TLColors.teal.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

extension View {
    func tlCard(padding: CGFloat = 16) -> some View {
        modifier(TLCardModifier(padding: padding))
    }

    func tlScreenBackground() -> some View {
        modifier(TLScreenBackgroundModifier())
    }

    func tlTabNavigationTitle(_ title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TLColors.background.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Components

struct TLSectionHeader: View {
    let title: String
    var icon: String?

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLColors.accentGradient)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(TLColors.primaryText)
            Spacer()
        }
    }
}

struct TLStatusBadge: View {
    let text: String
    var gradient: LinearGradient = TLColors.softFillGradient
    var textColor: Color = TLColors.tealDark

    init(text: String, color: Color) {
        self.text = text
        self.textColor = color
        if color == TLColors.income {
            gradient = LinearGradient(colors: [TLColors.income.opacity(0.15), TLColors.tealLight.opacity(0.25)], startPoint: .leading, endPoint: .trailing)
        } else if color == TLColors.pending {
            gradient = LinearGradient(colors: [Color.orange.opacity(0.12), Color.yellow.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
        } else {
            gradient = TLColors.softFillGradient
        }
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule().fill(gradient)
            }
    }
}

struct TLAvatarView: View {
    let name: String
    var size: CGFloat = 40

    private var initial: String { String(name.prefix(1)) }
    private var hue: Double { Double(abs(name.hashValue % 360)) }

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: hue / 360, saturation: 0.35, brightness: 0.88),
                                Color(hue: (hue + 25) / 360, saturation: 0.45, brightness: 0.72)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
    }
}

struct TLIconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.18), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
    }
}
