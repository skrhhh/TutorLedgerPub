import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LessonRecord.date, order: .reverse) private var allLessons: [LessonRecord]

    @State private var stats = DashboardStats()
    @State private var upcomingLessons: [(Student, Date)] = []
    @State private var showLogLesson = false
    @State private var logLessonStudent: Student?
    @State private var showPurchase = false
    @State private var purchaseStudent: Student?
    @State private var showAllLessons = DemoLaunch.openLessons
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var exportError: String?
    @State private var showExportError = false
    @State private var backupReminderVisible = AppSettings.shouldShowHomeBackupReminder

    private var recentLessons: [LessonRecord] {
        allLessons.filter { $0.billingStatus != .void }.prefix(8).map { $0 }
    }

    /// 作废、改金额不会改变条数，但首页数字必须跟着变。
    private var lessonFingerprint: String {
        allLessons.map { "\($0.id.uuidString)-\($0.billingStatusRaw)-\($0.amountCents)" }.joined(separator: "|")
    }

    var body: some View {
        NavigationStack {
            TLPageScaffold(
                title: String(localized: "课酬记"),
                subtitle: String(localized: "下课记一笔，对账不扯皮")
            ) {
                ScrollView {
                    VStack(spacing: 16) {
                        if backupReminderVisible, !allLessons.isEmpty {
                            backupReminderCard
                        }

                        Button { logLessonStudent = nil; showLogLesson = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("记课时")
                                        .font(.headline)
                                    Text("10 秒完成记录")
                                        .font(.caption)
                                        .opacity(0.9)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(18)
                            .background {
                                RoundedRectangle(cornerRadius: TLTheme.buttonRadius, style: .continuous)
                                    .fill(TLColors.breezeGradient)
                            }
                            .shadow(color: TLColors.teal.opacity(0.28), radius: 16, y: 8)
                        }
                        .buttonStyle(.plain)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                title: String(localized: "今日课时"),
                                value: String(localized: "\(stats.todayLessons) 节"),
                                icon: "sun.max.fill",
                                tint: TLColors.cyan
                            )
                            StatCard(
                                title: String(localized: "本周课时"),
                                value: String(localized: "\(stats.weekLessons) 节"),
                                icon: "calendar",
                                tint: TLColors.teal
                            )
                            StatCard(
                                title: String(localized: "本月已收"),
                                value: MoneyFormat.display(cents: stats.monthReceivedCents),
                                icon: "checkmark.circle.fill",
                                tint: TLColors.income
                            )
                            StatCard(
                                title: String(localized: "本月待收"),
                                value: MoneyFormat.display(cents: stats.monthPendingCents),
                                icon: "clock.fill",
                                tint: TLColors.pending
                            )
                        }

                        if !stats.lowPackageStudents.isEmpty {
                            TLFormCard(title: String(localized: "课包不足"), icon: "exclamationmark.circle.fill") {
                                ForEach(stats.lowPackageStudents, id: \.id) { student in
                                    HStack(spacing: 10) {
                                        NavigationLink {
                                            StudentDetailView(student: student)
                                        } label: {
                                            HStack {
                                                TLAvatarView(name: student.name, size: 32)
                                                Text(student.name)
                                                    .foregroundStyle(TLColors.primaryText)
                                                Spacer(minLength: 0)
                                                Text(String(localized: "剩 \(student.packageRemainingHours) 节"))
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(TLColors.pending)
                                            }
                                        }
                                        .buttonStyle(.plain)

                                        Button("续费") {
                                            purchaseStudent = student
                                            showPurchase = true
                                        }
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(TLColors.tealDark)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(TLColors.secondaryButtonGradient)
                                        .clipShape(Capsule())
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        if !upcomingLessons.isEmpty {
                            TLFormCard(title: String(localized: "即将上课"), icon: "calendar.badge.clock") {
                                ForEach(upcomingLessons, id: \.0.id) { student, date in
                                    HStack(spacing: 10) {
                                        NavigationLink {
                                            StudentDetailView(student: student)
                                        } label: {
                                            UpcomingLessonRowView(student: student, date: date)
                                        }
                                        .buttonStyle(.plain)

                                        Button("记一笔") {
                                            logLessonStudent = student
                                            showLogLesson = true
                                        }
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(TLColors.breezeGradient)
                                        .clipShape(Capsule())
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        TLFormCard(title: String(localized: "最近课时"), icon: "clock.arrow.circlepath") {
                            if recentLessons.isEmpty {
                                Text("还没有课时记录，点击上方按钮记第一笔")
                                    .font(.subheadline)
                                    .foregroundStyle(TLColors.secondaryText)
                            } else {
                                ForEach(Array(recentLessons.enumerated()), id: \.element.id) { index, lesson in
                                    NavigationLink {
                                        LessonDetailView(lesson: lesson)
                                    } label: {
                                        LessonRowView(lesson: lesson)
                                    }
                                    if index < recentLessons.count - 1 {
                                        Divider().padding(.leading, 56)
                                    }
                                }

                                NavigationLink {
                                    LessonsListView()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("查看全部课时")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(TLColors.teal)
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(TLColors.teal)
                                    }
                                    .padding(.top, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .tlKeyboardDismissibleScroll()
            }
            .navigationDestination(isPresented: $showAllLessons) {
                LessonsListView()
            }
            .onAppear {
                backupReminderVisible = AppSettings.shouldShowHomeBackupReminder
                refreshStats()
            }
            .onChange(of: lessonFingerprint) { _, _ in refreshStats() }
            .sheet(isPresented: $showLogLesson) {
                LogLessonView(preselectedStudent: logLessonStudent)
            }
            .sheet(isPresented: $showPurchase) {
                if let purchaseStudent {
                    PackagePurchaseView(student: purchaseStudent)
                }
            }
            .activityShareSheet(isPresented: $showShareSheet, items: shareItems) { completed in
                if completed {
                    AppSettings.lastExportDate = .now
                    backupReminderVisible = AppSettings.shouldShowHomeBackupReminder
                }
            }
            .alert("导出失败", isPresented: $showExportError) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private var backupReminderCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(TLColors.pending)
            VStack(alignment: .leading, spacing: 8) {
                Text("建议备份数据")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLColors.primaryText)
                Text("数据只在本机。换机或重装前请先导出 CSV。")
                    .font(.caption)
                    .foregroundStyle(TLColors.secondaryText)
                Button("导出") { exportBackup() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(TLColors.breezeGradient)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
            Button {
                AppSettings.dismissHomeBackupReminder()
                withAnimation(.easeInOut(duration: 0.2)) {
                    backupReminderVisible = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLColors.secondaryText)
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "关闭备份提醒"))
        }
        .tlCard(padding: 14)
    }

    private func exportBackup() {
        do {
            let csv = try ExportService.makeCSV(context: modelContext)
            shareItems = [try ShareService.temporaryCSVURL(from: csv)]
            showShareSheet = true
            AnalyticsService.exportCSV(source: "home")
        } catch {
            exportError = error.localizedDescription
            showExportError = true
            AnalyticsService.recordError(error, context: "home_export")
        }
    }

    private func refreshStats() {
        stats = StatsService.dashboardStats(context: modelContext)
        upcomingLessons = StatsService.upcomingLessons(context: modelContext)
    }
}
