import SwiftUI

enum TLColors {
    // MARK: - Brand · 春风青绿
    static let teal = Color(red: 0.28, green: 0.78, blue: 0.74)
    static let tealLight = Color(red: 0.55, green: 0.90, blue: 0.87)
    static let tealDark = Color(red: 0.18, green: 0.62, blue: 0.58)
    static let cyan = Color(red: 0.38, green: 0.84, blue: 0.88)
    static let mint = Color(red: 0.82, green: 0.96, blue: 0.94)
    static let sky = Color(red: 0.72, green: 0.92, blue: 0.98)
    static let spring = Color(red: 0.90, green: 0.98, blue: 0.95)

    static var accent: Color { teal }

    /// 主品牌渐变 ·  cyan → teal
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, teal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 春风渐变 · 按钮、高亮
    static var breezeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.88, blue: 0.86),
                Color(red: 0.30, green: 0.78, blue: 0.82),
                Color(red: 0.22, green: 0.70, blue: 0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 柔和底纹渐变 · 输入框、未选中 Chip
    static var softFillGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.97, blue: 0.96),
                Color(red: 0.94, green: 0.99, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var softFillGradientDark: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.20, blue: 0.21),
                Color(red: 0.10, green: 0.16, blue: 0.17)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 卡片渐变 · 白 → 淡薄荷
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                Color(red: 0.96, green: 0.99, blue: 0.99),
                Color(red: 0.92, green: 0.98, blue: 0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGradientDark: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.14, green: 0.19, blue: 0.20),
                Color(red: 0.11, green: 0.15, blue: 0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 收入渐变 · 清新绿
    static var incomeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.35, green: 0.88, blue: 0.72),
                Color(red: 0.18, green: 0.72, blue: 0.58)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 待收渐变 · 暖杏（愉快而非告警）
    static var pendingGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.78, blue: 0.52),
                Color(red: 0.98, green: 0.62, blue: 0.38)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 次要按钮渐变
    static var secondaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.90, green: 0.98, blue: 0.97),
                Color(red: 0.82, green: 0.95, blue: 0.93)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentSoft: Color {
        mint.opacity(0.55)
    }

    // MARK: - Surfaces
    static var background: Color {
        Color(red: 0.94, green: 0.99, blue: 0.98)
    }

    /// 页面背景 · 天空 → 春风 → 薄荷
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.78, green: 0.94, blue: 0.98), location: 0),
                .init(color: Color(red: 0.88, green: 0.97, blue: 0.96), location: 0.35),
                .init(color: Color(red: 0.94, green: 0.99, blue: 0.98), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var card: Color { .white }

    static var cardBorder: Color {
        teal.opacity(0.14)
    }

    // MARK: - Semantic（保留 Color 供图标等，展示用 gradient）
    static let income = Color(red: 0.22, green: 0.74, blue: 0.58)
    static let pending = Color(red: 0.96, green: 0.62, blue: 0.36)
    static let danger = Color(red: 0.94, green: 0.42, blue: 0.48)

    static var primaryText: Color {
        Color(red: 0.12, green: 0.28, blue: 0.27)
    }

    static var secondaryText: Color {
        Color(red: 0.45, green: 0.58, blue: 0.57)
    }

    /// 金额文字渐变
    static func moneyGradient(tint: LinearGradient? = nil) -> LinearGradient {
        tint ?? incomeGradient
    }
}

extension View {
    @ViewBuilder
    func tlGradientForeground(_ gradient: LinearGradient) -> some View {
        self.foregroundStyle(gradient)
    }
}
