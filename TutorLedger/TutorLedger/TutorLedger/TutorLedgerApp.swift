import SwiftUI

@main
struct TutorLedgerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let bootstrap = AppModelContainerBootstrap.load()

    var body: some Scene {
        WindowGroup {
            TutorLedgerRootView(bootstrap: bootstrap)
                .preferredColorScheme(.light)
        }
    }
}

struct TutorLedgerRootView: View {
    let bootstrap: AppModelContainerBootstrap
    @State private var showLaunchAnimation = true

    var body: some View {
        switch bootstrap {
        case .ready(let container, let isInMemoryFallback):
            ZStack {
                ContentView(isAppReady: !showLaunchAnimation)
                    .installKeyboardDismissOnTap()
                    .safeAreaInset(edge: .top, spacing: 0) {
                        if isInMemoryFallback {
                            Text(String(localized: "数据仅保存在内存中，重启后将丢失"))
                                .font(.footnote)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background {
                                    LinearGradient(
                                        colors: [TLColors.pending.opacity(0.12), Color.orange.opacity(0.08)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                        }
                    }
                    .modelContainer(container)
                    .opacity(showLaunchAnimation ? 0 : 1)

                if showLaunchAnimation {
                    LaunchAnimationView {
                        showLaunchAnimation = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: showLaunchAnimation)
        case .failed(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(TLColors.pending)
                Text(String(localized: "应用启动失败"))
                    .font(.headline)
                    .foregroundStyle(TLColors.primaryText)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(TLColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tlScreenBackground()
        }
    }
}

struct ContentView: View {
    var isAppReady: Bool = true

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: TLTab = .home

    private var showOnboarding: Bool {
        isAppReady && !hasCompletedOnboarding
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home: HomeView()
                case .students: StudentsListView()
                case .bills: BillsView()
                case .stats: StatsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 72)

            TLCustomTabBar(selected: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: Binding(
            get: { showOnboarding },
            set: { presented in
                if !presented { hasCompletedOnboarding = true }
            }
        )) {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        }
    }
}
