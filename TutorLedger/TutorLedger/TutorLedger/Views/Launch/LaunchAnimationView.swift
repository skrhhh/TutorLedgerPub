import SwiftUI

struct LaunchAnimationView: View {
    let onComplete: () -> Void

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 12
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            TLColors.backgroundGradient
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [TLColors.cyan.opacity(0.22), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 80, y: -160)
                .allowsHitTesting(false)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [TLColors.tealLight.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: -100, y: 220)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [TLColors.tealLight.opacity(0.5), TLColors.cyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 128, height: 128)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Circle()
                        .fill(TLColors.breezeGradient)
                        .frame(width: 108, height: 108)
                        .shadow(color: TLColors.teal.opacity(0.35), radius: 24, y: 12)

                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 10) {
                    Text("课酬记")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(TLColors.tealDark)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    Text("记录课时，算清课酬")
                        .font(.body)
                        .foregroundStyle(TLColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 36)
                .padding(.top, 28)
                .opacity(titleOpacity)
                .offset(y: titleOffset)

                Spacer()

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(TLColors.softFillGradient)
                    Capsule()
                        .fill(TLColors.breezeGradient)
                        .scaleEffect(x: max(progress, 0.001), y: 1, anchor: .leading)
                }
                .frame(height: 4)
                .padding(.horizontal, 48)
                .padding(.bottom, 56)
                .opacity(subtitleOpacity)
            }
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
            logoScale = 1
            logoOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
            ringScale = 1.15
            ringOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.7).delay(0.55)) {
            titleOpacity = 1
            subtitleOpacity = 1
            titleOffset = 0
        }
        withAnimation(.linear(duration: 5).delay(0.3)) {
            progress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(.easeInOut(duration: 0.35)) {
                logoOpacity = 0
                titleOpacity = 0
                subtitleOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onComplete()
            }
        }
    }
}
