import SwiftData
import SwiftUI

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var displayedMonth = Date.now
    @State private var selectedDay = Calendar.current.startOfDay(for: .now)
    @State private var lessonDays: Set<Date> = []
    @State private var daySummary = DayLessonSummary()
    @State private var receivedByStudent: [(Student, Int)] = []
    @State private var lessonsByStudent: [(Student, Int)] = []
    @State private var lessonCount = 0
    @State private var totalHours = 0.0

    private var monthTitle: String {
        TLDateFormat.yearMonth(displayedMonth)
    }

    private var selectedDayTitle: String {
        TLDateFormat.monthDayWeekday(selectedDay)
    }

    private var totalReceived: Int {
        receivedByStudent.reduce(0) { $0 + $1.1 }
    }

    var body: some View {
        NavigationStack {
            TLPageScaffold(title: String(localized: "统计"), subtitle: monthTitle) {
                ScrollView {
                    VStack(spacing: 16) {
                        TLFormCard(title: String(localized: "选择日期"), icon: "calendar") {
                            TLStatsCalendarView(
                                displayedMonth: $displayedMonth,
                                selectedDay: $selectedDay,
                                lessonDays: lessonDays
                            )
                        }

                        dayDetailSection

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                title: String(localized: "本月课时"),
                                value: String(localized: "\(lessonCount) 节"),
                                icon: "book.fill",
                                tint: TLColors.teal
                            )
                            StatCard(
                                title: String(localized: "本月时长"),
                                value: MoneyFormat.display(hours: totalHours),
                                icon: "hourglass",
                                tint: TLColors.cyan
                            )
                        }

                        TLMoneyHero(
                            amount: MoneyFormat.display(cents: totalReceived),
                            label: String(localized: "本月已收"),
                            gradient: TLColors.incomeGradient
                        )
                        .tlCard(padding: 14)

                        if !receivedByStudent.isEmpty {
                            TLFormCard(title: String(localized: "收入分布"), icon: "chart.bar.fill") {
                                TLBarChart(
                                    values: receivedByStudent.prefix(5).map {
                                        CGFloat($0.1) / CGFloat(max(totalReceived, 1))
                                    },
                                    labels: receivedByStudent.prefix(5).map {
                                        String($0.0.name.prefix(2))
                                    }
                                )
                            }
                        }

                        TLFormCard(title: String(localized: "学生贡献"), icon: "person.2.fill") {
                            if receivedByStudent.isEmpty {
                                Text("本月暂无已收款记录")
                                    .font(.subheadline)
                                    .foregroundStyle(TLColors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(Array(receivedByStudent.enumerated()), id: \.element.0.id) { index, item in
                                    let (student, amount) = item
                                    HStack(spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .frame(width: 24, height: 24)
                                            .background(rankGradient(index))
                                            .clipShape(Circle())
                                        TLAvatarView(name: student.name, size: 36)
                                        Text(student.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(TLColors.primaryText)
                                        Spacer()
                                        Text(MoneyFormat.display(cents: amount))
                                            .font(.subheadline.bold())
                                            .foregroundStyle(TLColors.incomeGradient)
                                    }
                                    .padding(.vertical, 4)
                                    if index < receivedByStudent.count - 1 { Divider() }
                                }
                            }
                        }

                        TLFormCard(title: String(localized: "上课最多"), icon: "book.fill") {
                            if lessonsByStudent.isEmpty {
                                Text("本月暂无课时记录")
                                    .font(.subheadline)
                                    .foregroundStyle(TLColors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(Array(lessonsByStudent.enumerated()), id: \.element.0.id) { index, item in
                                    let (student, count) = item
                                    HStack(spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .frame(width: 24, height: 24)
                                            .background(rankGradient(index))
                                            .clipShape(Circle())
                                        TLAvatarView(name: student.name, size: 36)
                                        Text(student.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(TLColors.primaryText)
                                        Spacer()
                                        Text(String(localized: "\(count) 节"))
                                            .font(.subheadline.bold())
                                            .foregroundStyle(TLColors.accentGradient)
                                    }
                                    .padding(.vertical, 4)
                                    if index < lessonsByStudent.count - 1 { Divider() }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .tlKeyboardDismissibleScroll()
            }
            .onAppear { refreshAll() }
            .onChange(of: displayedMonth) { _, _ in refreshMonthData() }
            .onChange(of: selectedDay) { _, _ in refreshDayData() }
        }
    }

    @ViewBuilder
    private var dayDetailSection: some View {
        TLFormCard(title: selectedDayTitle, icon: "list.bullet.rectangle") {
            if daySummary.lessonCount == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.title2)
                        .foregroundStyle(TLColors.secondaryText.opacity(0.6))
                    Text("这一天没有课时记录")
                        .font(.subheadline)
                        .foregroundStyle(TLColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                HStack(spacing: 12) {
                    dayStatPill(
                        title: String(localized: "课时"),
                        value: String(localized: "\(daySummary.lessonCount) 节")
                    )
                    dayStatPill(
                        title: String(localized: "时长"),
                        value: MoneyFormat.display(hours: daySummary.totalHours)
                    )
                    dayStatPill(
                        title: String(localized: "已收"),
                        value: MoneyFormat.display(cents: daySummary.receivedCents)
                    )
                }

                ForEach(Array(daySummary.lessons.enumerated()), id: \.element.id) { index, lesson in
                    NavigationLink {
                        LessonDetailView(lesson: lesson)
                    } label: {
                        LessonRowView(lesson: lesson)
                    }
                    .buttonStyle(.plain)
                    if index < daySummary.lessons.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
    }

    private func dayStatPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(TLColors.secondaryText)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLColors.tealDark)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(TLColors.softFillGradient)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func rankGradient(_ index: Int) -> LinearGradient {
        switch index {
        case 0: return TLColors.breezeGradient
        case 1: return TLColors.accentGradient
        case 2: return LinearGradient(colors: [TLColors.tealLight, TLColors.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [TLColors.secondaryText.opacity(0.5), TLColors.secondaryText.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        }
    }

    private func refreshAll() {
        refreshMonthData()
        refreshDayData()
    }

    private func refreshMonthData() {
        receivedByStudent = StatsService.monthReceivedByStudent(context: modelContext, month: displayedMonth)
        lessonsByStudent = StatsService.monthLessonsByStudent(context: modelContext, month: displayedMonth)
        lessonCount = StatsService.monthLessonCount(context: modelContext, month: displayedMonth)
        totalHours = StatsService.monthTotalHours(context: modelContext, month: displayedMonth)
        lessonDays = StatsService.lessonDaysInMonth(context: modelContext, month: displayedMonth)
    }

    private func refreshDayData() {
        daySummary = StatsService.dayLessonSummary(context: modelContext, day: selectedDay)
    }
}
