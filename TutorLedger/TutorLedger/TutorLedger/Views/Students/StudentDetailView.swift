import SwiftData
import SwiftUI

private enum StudentDetailTab: String, CaseIterable, Identifiable {
    case overview, lessons, bills, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .overview: String(localized: "概览")
        case .lessons: String(localized: "课时")
        case .bills: String(localized: "账单")
        case .settings: String(localized: "设置")
        }
    }
}

struct StudentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var student: Student

    @State private var selectedTab: StudentDetailTab = .overview
    @State private var showLogLesson = false
    @State private var showPurchase = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showVoidedLessons = false

    private var sortedLessons: [LessonRecord] {
        student.lessons
            .filter { showVoidedLessons || $0.billingStatus != .void }
            .sorted { $0.date > $1.date }
    }

    private var voidedLessonCount: Int {
        student.lessons.filter { $0.billingStatus == .void }.count
    }

    private var sortedBills: [Bill] {
        student.bills.sorted { $0.createdAt > $1.createdAt }
    }

    private var sortedPackageTransactions: [PackageTransaction] {
        student.packageTransactions.sorted { $0.date > $1.date }
    }

    var body: some View {
        TLPageScaffold(
            title: student.name,
            subtitle: "\(student.grade.title) · \(student.primarySubject)",
            showBack: true,
            trailingTitle: String(localized: "记一笔"),
            onTrailing: { showLogLesson = true }
        ) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(StudentDetailTab.allCases) { tab in
                        TLFilterChip(title: tab.title, isSelected: selectedTab == tab) {
                            selectedTab = tab
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .overview: overviewTab
                        case .lessons: lessonsTab
                        case .bills: billsTab
                        case .settings: settingsTab
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .tlKeyboardDismissibleScroll()
            }
        }
        .sheet(isPresented: $showLogLesson) { LogLessonView(preselectedStudent: student) }
        .sheet(isPresented: $showPurchase) { PackagePurchaseView(student: student) }
        .sheet(isPresented: $showEdit) { AddEditStudentView(student: student) }
        .confirmationDialog("删除学生？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除全部数据", role: .destructive) { deleteStudent() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将永久删除该学生及其所有课时、账单和课包记录，此操作不可恢复。")
        }
        .alert("操作失败", isPresented: $showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var overviewTab: some View {
        HStack(spacing: 14) {
            TLAvatarView(name: student.name, size: 52)
            VStack(alignment: .leading, spacing: 6) {
                TLStatusBadge(text: student.billingMode.title, color: TLColors.teal)
                TLStatusBadge(text: student.status.title, color: TLColors.secondaryText)
                Text(String(format: String(localized: "%@/小时"), MoneyFormat.display(cents: student.defaultUnitPriceCents)))
                    .font(.headline)
                    .foregroundStyle(TLColors.teal)
            }
            Spacer()
        }
        .tlCard(padding: 14)

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if student.billingMode == .prepaid {
                StatCard(
                    title: String(localized: "剩余课时"),
                    value: String(localized: "\(student.packageRemainingHours) 节"),
                    icon: "ticket.fill",
                    tint: student.isLowPackage ? TLColors.pending : TLColors.teal
                )
            }
            if student.pendingAmountCents > 0 {
                StatCard(
                    title: String(localized: "待收金额"),
                    value: MoneyFormat.display(cents: student.pendingAmountCents),
                    icon: "clock.fill",
                    tint: TLColors.pending
                )
            }
            StatCard(
                title: String(localized: "累计课时"),
                value: String(localized: "\(sortedLessons.count) 节"),
                icon: "book.fill",
                tint: TLColors.cyan
            )
        }

        if let next = student.nextLessonAt {
            TLFormCard(title: String(localized: "下次上课"), icon: "calendar.badge.clock") {
                Text(TLDateFormat.mediumDateTime(next))
                    .font(.subheadline)
                    .foregroundStyle(TLColors.secondaryText)
            }
        }

        if let latest = sortedLessons.first {
            TLFormCard(title: String(localized: "最近上课"), icon: "clock.arrow.circlepath") {
                Text("\(TLDateFormat.mediumDateTime(latest.date)) · \(latest.subject) · \(MoneyFormat.display(cents: latest.amountCents))")
                    .font(.subheadline)
                    .foregroundStyle(TLColors.secondaryText)
            }
        }

        if student.billingMode == .prepaid {
            Button("购课 / 续费") { showPurchase = true }
                .buttonStyle(TLSecondaryButtonStyle())
        }

        if student.billingMode == .prepaid, !sortedPackageTransactions.isEmpty {
            TLFormCard(title: String(localized: "课包流水"), icon: "arrow.left.arrow.right") {
                ForEach(Array(sortedPackageTransactions.prefix(10).enumerated()), id: \.element.id) { index, transaction in
                    PackageTransactionRowView(transaction: transaction)
                    if index < min(sortedPackageTransactions.count, 10) - 1 {
                        Divider().padding(.leading, 4)
                    }
                }
                if sortedPackageTransactions.count > 10 {
                    Text("仅显示最近 10 条")
                        .font(.caption2)
                        .foregroundStyle(TLColors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var lessonsTab: some View {
        if voidedLessonCount > 0 {
            Toggle(
                String(localized: "显示已作废（\(voidedLessonCount)）"),
                isOn: $showVoidedLessons
            )
            .tint(TLColors.teal)
            .padding(.horizontal, 4)
        }

        if sortedLessons.isEmpty {
            EmptyStateView(
                icon: "book.fill",
                title: String(localized: "暂无课时"),
                message: String(localized: "点击右上角「记一笔」开始记录")
            )
        } else {
            ForEach(sortedLessons) { lesson in
                NavigationLink {
                    LessonDetailView(lesson: lesson)
                } label: {
                    LessonRowView(lesson: lesson).tlCard(padding: 14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var billsTab: some View {
        if sortedBills.isEmpty {
            EmptyStateView(
                icon: "doc.text",
                title: String(localized: "暂无账单"),
                message: String(localized: "在「账单」页为待结算课时生成账单")
            )
        } else {
            ForEach(sortedBills) { bill in
                NavigationLink {
                    BillDetailView(bill: bill)
                } label: {
                    HStack(spacing: 12) {
                        TLIconBadge(icon: "doc.text.fill", color: TLColors.teal, size: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bill.periodTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TLColors.primaryText)
                            Text(String(localized: "\(bill.lessons.count) 节课"))
                                .font(.caption)
                                .foregroundStyle(TLColors.secondaryText)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(MoneyFormat.display(cents: bill.totalAmountCents))
                                .font(.subheadline.bold())
                            TLStatusBadge(
                                text: bill.status.title,
                                color: bill.status == .paid ? TLColors.income : TLColors.pending
                            )
                        }
                    }
                    .tlCard(padding: 14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var settingsTab: some View {
        Button("编辑学生信息") { showEdit = true }
            .buttonStyle(TLSecondaryButtonStyle())

        if !student.note.isEmpty {
            TLFormCard(title: String(localized: "备注"), icon: "note.text") {
                Text(student.note)
                    .font(.subheadline)
                    .foregroundStyle(TLColors.secondaryText)
            }
        }

        Button("删除学生") { showDeleteConfirm = true }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(TLColors.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }

    private func deleteStudent() {
        do {
            try BillingService.deleteStudent(student, context: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
