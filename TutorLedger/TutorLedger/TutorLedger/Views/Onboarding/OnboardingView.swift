import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var page = 0

    private var pages: [(icon: String, title: String, subtitle: String)] {
        [
            (
                "person.badge.plus",
                String(localized: "添加学生"),
                String(localized: "录入姓名、计费方式和默认单价，支持先付课包、课后结算、按次现结")
            ),
            (
                "plus.circle.fill",
                String(localized: "记课时"),
                String(localized: "下课后 10 秒记一笔，可当场添加新学生，单价自动带出")
            ),
            (
                "doc.text.fill",
                String(localized: "对账收款"),
                String(localized: "在账单页汇总待收、生成账单分享 CSV，记得定期备份")
            ),
            (
                "arrow.triangle.2.circlepath",
                String(localized: "账单状态"),
                String(localized: "待发送：已生成未发给家长 · 已发送：已发给家长待收款 · 已收款：钱已到账")
            )
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 28) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [TLColors.cyan.opacity(0.22), TLColors.mint.opacity(0.06)],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 140, height: 140)
                            Image(systemName: item.icon)
                                .font(.system(size: 52, weight: .medium))
                                .foregroundStyle(TLColors.breezeGradient)
                        }

                        VStack(spacing: 12) {
                            Text(item.title)
                                .font(.title2.bold())
                                .foregroundStyle(TLColors.primaryText)
                            Text(item.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(TLColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 12) {
                if page < pages.count - 1 {
                    Button("下一步") { withAnimation { page += 1 } }
                        .buttonStyle(TLPrimaryButtonStyle())
                    Button("跳过") { finish() }
                        .font(.subheadline)
                        .foregroundStyle(TLColors.secondaryText)
                } else {
                    Button("开始使用") { finish() }
                        .buttonStyle(TLPrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .tlScreenBackground()
    }

    private func finish() {
        onComplete()
    }
}
