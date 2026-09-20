import SwiftData
import SwiftUI
import UIKit

struct BillsView: View {
    @Query(sort: \Student.name) private var students: [Student]
    @Query(sort: \Bill.createdAt, order: .reverse) private var bills: [Bill]
    @Query(sort: \LessonRecord.date, order: .reverse) private var lessons: [LessonRecord]

    @State private var viewMode: BillsViewMode = .pendingToBill
    @State private var timePreset: BillsTimePreset = .all
    @State private var customRangeStart: Date = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: .now)
    ) ?? .now
    @State private var customRangeEnd: Date = .now
    @State private var statusFilter: BillsStatusFilter = .all
    @State private var selectedStudentID: UUID?
    @State private var filtersExpanded = false
    @State private var expandedFilterCategory: BillsFilterCategory?
    @State private var expandedStudentIDs: Set<UUID> = []
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var shareError: String?
    @State private var showShareError = false

    private var activeDateRange: BillsDateRange {
        BillsDateRange.resolve(
            preset: timePreset,
            customStart: customRangeStart,
            customEnd: customRangeEnd
        )
    }

    private var timeRangeTitle: String {
        BillsDateRange.displayTitle(
            preset: timePreset,
            customStart: customRangeStart,
            customEnd: customRangeEnd
        )
    }

    private func pendingLessons(for student: Student) -> [LessonRecord] {
        lessons.filter { lesson in
            guard lesson.student?.id == student.id, lesson.billingStatus == .pending else { return false }
            return activeDateRange.contains(lesson.date)
        }
    }

    private var pendingByStudent: [(Student, [LessonRecord], Int)] {
        students.compactMap { student in
            if let selectedStudentID, student.id != selectedStudentID { return nil }
            let pending = pendingLessons(for: student)
            guard !pending.isEmpty else { return nil }
            let total = pending.reduce(0) { $0 + $1.amountCents }
            return (student, pending, total)
        }
    }

    private var filteredBills: [Bill] {
        bills.filter { bill in
            if let selectedStudentID, bill.student?.id != selectedStudentID { return false }
            if !statusFilter.matches(bill.status) { return false }
            return activeDateRange.overlaps(periodStart: bill.periodStart, periodEnd: bill.periodEnd)
        }
    }

    private var billsGroupedByStudent: [(Student, [Bill], Int)] {
        var groups: [UUID: (Student, [Bill])] = [:]
        for bill in filteredBills {
            guard let student = bill.student else { continue }
            if groups[student.id] == nil {
                groups[student.id] = (student, [])
            }
            groups[student.id]!.1.append(bill)
        }
        return groups.values
            .map { student, studentBills in
                let sorted = studentBills.sorted { $0.createdAt > $1.createdAt }
                let total = sorted.reduce(0) { $0 + $1.totalAmountCents }
                return (student, sorted, total)
            }
            .sorted { $0.0.name.localizedCompare($1.0.name) == .orderedAscending }
    }

    private var totalPendingCents: Int {
        pendingByStudent.reduce(0) { $0 + $1.2 }
    }

    private var pageSubtitle: String {
        switch viewMode {
        case .pendingToBill:
            if pendingByStudent.isEmpty { return String(localized: "暂无待出账课时") }
            return String(
                localized: "待收 \(MoneyFormat.display(cents: totalPendingCents)) · \(pendingByStudent.count) 位学生"
            )
        case .issued:
            if filteredBills.isEmpty { return String(localized: "暂无账单") }
            return String(
                localized: "\(filteredBills.count) 张账单 · \(billsGroupedByStudent.count) 位学生"
            )
        }
    }

    private var filterSummary: String {
        var parts = [timeRangeTitle]
        if viewMode == .issued {
            parts.append(statusFilter.title)
        }
        if let selectedStudentID, let student = students.first(where: { $0.id == selectedStudentID }) {
            parts.append(student.name)
        } else {
            parts.append(String(localized: "全部学生"))
        }
        return parts.joined(separator: " · ")
    }

    private var selectedStudentName: String? {
        guard let selectedStudentID else { return nil }
        return students.first(where: { $0.id == selectedStudentID })?.name
    }

    private var hasExportableContent: Bool {
        switch viewMode {
        case .pendingToBill: !pendingByStudent.isEmpty
        case .issued: !filteredBills.isEmpty
        }
    }

    private var exportScopeDescription: String {
        filterSummary
    }

    private var exportScope: ExportService.ExportScope {
        ExportService.ExportScope(
            type: viewMode.title,
            timeRange: timeRangeTitle,
            student: selectedStudentName ?? String(localized: "全部学生"),
            status: viewMode == .issued ? statusFilter.title : nil
        )
    }

    var body: some View {
        NavigationStack {
            TLPageScaffold(title: String(localized: "账单"), subtitle: pageSubtitle) {
                ScrollView {
                    VStack(spacing: 16) {
                        conceptHintCard

                        HStack(spacing: 8) {
                            ForEach(BillsViewMode.allCases) { mode in
                                TLFilterChip(title: mode.title, isSelected: viewMode == mode) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewMode = mode
                                        expandedFilterCategory = nil
                                    }
                                }
                            }
                        }

                        filterPanel

                        if hasExportableContent {
                            exportBar
                        }

                        switch viewMode {
                        case .pendingToBill:
                            pendingContent
                        case .issued:
                            issuedBillsContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .tlKeyboardDismissibleScroll()
            }
            .onAppear { syncExpandedStudents() }
            .onChange(of: billsGroupedByStudent.map(\.0.id)) { _, _ in syncExpandedStudents() }
            .activityShareSheet(isPresented: $showShareSheet, items: shareItems)
            .alert("分享失败", isPresented: $showShareError) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(shareError ?? "")
            }
        }
    }

    private var conceptHintCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: viewMode == .pendingToBill ? "tray.full.fill" : "doc.text.fill")
                .font(.title3)
                .foregroundStyle(TLColors.breezeGradient)
            VStack(alignment: .leading, spacing: 4) {
                Text(viewMode.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLColors.primaryText)
                Text(viewMode.subtitle)
                    .font(.caption)
                    .foregroundStyle(TLColors.secondaryText)
                if viewMode == .pendingToBill {
                    Text("账单按学生汇总多节课时，不是每节课一张账单")
                        .font(.caption2)
                        .foregroundStyle(TLColors.teal)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .tlCard(padding: 14)
    }

    private var filterPanel: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    filtersExpanded.toggle()
                    if !filtersExpanded { expandedFilterCategory = nil }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(TLColors.teal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("筛选")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TLColors.primaryText)
                        Text(filterSummary)
                            .font(.caption)
                            .foregroundStyle(TLColors.secondaryText)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: filtersExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLColors.secondaryText)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if filtersExpanded {
                Divider().padding(.horizontal, 14)

                VStack(spacing: 0) {
                    filterCategoryRow(.time) {
                        VStack(alignment: .leading, spacing: 12) {
                            FlowLayout(spacing: 8) {
                                ForEach(BillsTimePreset.allCases) { preset in
                                    TLFilterChip(title: preset.title, isSelected: timePreset == preset) {
                                        timePreset = preset
                                    }
                                }
                            }
                            if timePreset == .custom {
                                DatePicker("开始日期", selection: $customRangeStart, displayedComponents: .date)
                                    .tint(TLColors.teal)
                                DatePicker("结束日期", selection: $customRangeEnd, displayedComponents: .date)
                                    .tint(TLColors.teal)
                            }
                        }
                    }

                    if viewMode == .issued {
                        Divider().padding(.horizontal, 14)
                        filterCategoryRow(.status) {
                            FlowLayout(spacing: 8) {
                                ForEach(BillsStatusFilter.allCases) { status in
                                    TLFilterChip(title: status.title, isSelected: statusFilter == status) {
                                        statusFilter = status
                                    }
                                }
                            }
                        }
                    }

                    Divider().padding(.horizontal, 14)
                    filterCategoryRow(.student) {
                        FlowLayout(spacing: 8) {
                            TLFilterChip(title: String(localized: "全部学生"), isSelected: selectedStudentID == nil) {
                                selectedStudentID = nil
                            }
                            ForEach(students.filter { $0.status == .active }) { student in
                                TLFilterChip(title: student.name, isSelected: selectedStudentID == student.id) {
                                    selectedStudentID = student.id
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 10)
            }
        }
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
    }

    @ViewBuilder
    private func filterCategoryRow(_ category: BillsFilterCategory, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedFilterCategory = expandedFilterCategory == category ? nil : category
                }
            } label: {
                HStack {
                    Text(category.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TLColors.primaryText)
                    Spacer()
                    Text(selectedLabel(for: category))
                        .font(.caption)
                        .foregroundStyle(TLColors.teal)
                    Image(systemName: expandedFilterCategory == category ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TLColors.secondaryText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if expandedFilterCategory == category {
                content()
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }
        }
    }

    private func selectedLabel(for category: BillsFilterCategory) -> String {
        switch category {
        case .time:
            return timeRangeTitle
        case .status:
            return statusFilter.title
        case .student:
            if let selectedStudentID, let student = students.first(where: { $0.id == selectedStudentID }) {
                return student.name
            }
            return String(localized: "全部学生")
        }
    }

    private var exportBar: some View {
        Button {
            shareCurrentFilter()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundStyle(TLColors.breezeGradient)
                VStack(alignment: .leading, spacing: 4) {
                    Text("分享当前筛选 CSV")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLColors.primaryText)
                    Text(exportScopeDescription)
                        .font(.caption)
                        .foregroundStyle(TLColors.secondaryText)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLColors.secondaryText)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .tlCard(padding: 0)
    }

    @ViewBuilder
    private var pendingContent: some View {
        if pendingByStudent.isEmpty {
            EmptyStateView(
                icon: "checkmark.circle.fill",
                title: String(localized: "暂无待出账课时"),
                message: timePreset == .all
                    ? String(localized: "课后结算的课时会出现在这里，选中学生后可生成账单")
                    : String(localized: "\(timeRangeTitle)没有待出账课时，试试调整筛选")
            )
            .padding(.top, 8)
        } else {
            TLMoneyHero(
                amount: MoneyFormat.display(cents: totalPendingCents),
                label: String(localized: "待出账合计"),
                gradient: TLColors.pendingGradient
            )
            .tlCard(padding: 14)

            ForEach(pendingByStudent, id: \.0.id) { student, pendingLessons, total in
                studentPendingSection(student: student, pendingLessons: pendingLessons, total: total)
            }
        }
    }

    @ViewBuilder
    private func studentPendingSection(student: Student, pendingLessons: [LessonRecord], total: Int) -> some View {
        TLFormCard(title: student.name, icon: "person.fill") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "\(pendingLessons.count) 节课待出账"))
                        .font(.caption)
                        .foregroundStyle(TLColors.secondaryText)
                    Text(MoneyFormat.display(cents: total))
                        .font(.headline.bold())
                        .foregroundStyle(TLColors.pendingGradient)
                }
                Spacer()
                NavigationLink {
                    CreateBillView(student: student, pendingLessons: pendingLessons)
                } label: {
                    Text("生成账单")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(TLColors.breezeGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Divider()

            ForEach(pendingLessons.prefix(3)) { lesson in
                HStack {
                    Text(TLDateFormat.monthDay(lesson.date))
                        .font(.caption)
                        .foregroundStyle(TLColors.secondaryText)
                    Text(lesson.subject)
                        .font(.caption)
                        .foregroundStyle(TLColors.primaryText)
                    Spacer()
                    Text(MoneyFormat.display(cents: lesson.amountCents))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(TLColors.secondaryText)
                }
            }
            if pendingLessons.count > 3 {
                Text(String(localized: "还有 \(pendingLessons.count - 3) 节课…"))
                    .font(.caption2)
                    .foregroundStyle(TLColors.secondaryText)
            }
        }
    }

    @ViewBuilder
    private var issuedBillsContent: some View {
        if filteredBills.isEmpty {
            EmptyStateView(
                icon: "doc.text",
                title: String(localized: "暂无账单"),
                message: bills.isEmpty
                    ? String(localized: "在「待出账」中为学生勾选课时，生成第一张账单")
                    : String(localized: "当前筛选条件下没有账单，试试调整筛选")
            )
            .padding(.top, 8)
        } else {
            ForEach(billsGroupedByStudent, id: \.0.id) { student, studentBills, total in
                studentIssuedSection(student: student, bills: studentBills, total: total)
            }
        }
    }

    @ViewBuilder
    private func studentIssuedSection(student: Student, bills: [Bill], total: Int) -> some View {
        let isExpanded = expandedStudentIDs.contains(student.id)
        let unpaidCount = bills.filter { $0.status != .paid }.count

        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedStudentIDs.remove(student.id)
                    } else {
                        expandedStudentIDs.insert(student.id)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    TLAvatarView(name: student.name, size: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(student.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TLColors.primaryText)
                        Text(String(localized: "\(bills.count) 张账单 · 合计 \(MoneyFormat.display(cents: total))"))
                            .font(.caption)
                            .foregroundStyle(TLColors.secondaryText)
                    }
                    Spacer()
                    if unpaidCount > 0 {
                        Text(String(localized: "\(unpaidCount) 待收"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(TLColors.pending)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(TLColors.softFillGradient)
                            .clipShape(Capsule())
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLColors.secondaryText)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.leading, 66)
                VStack(spacing: 0) {
                    ForEach(Array(bills.enumerated()), id: \.element.id) { index, bill in
                        NavigationLink {
                            BillDetailView(bill: bill)
                        } label: {
                            billRow(bill)
                        }
                        .buttonStyle(.plain)
                        if index < bills.count - 1 {
                            Divider().padding(.leading, 66)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
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
    }

    private func billRow(_ bill: Bill) -> some View {
        HStack(spacing: 12) {
            TLIconBadge(icon: "doc.text.fill", color: bill.status == .paid ? TLColors.income : TLColors.pending, size: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.periodTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TLColors.primaryText)
                Text(String(localized: "\(bill.lessons.count) 节课"))
                    .font(.caption)
                    .foregroundStyle(TLColors.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(MoneyFormat.display(cents: bill.totalAmountCents))
                    .font(.subheadline.bold())
                    .foregroundStyle(bill.status == .paid ? TLColors.incomeGradient : TLColors.pendingGradient)
                TLStatusBadge(
                    text: bill.status.title,
                    color: bill.status == .paid ? TLColors.income : TLColors.pending
                )
            }
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(TLColors.secondaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func shareCurrentFilter() {
        switch viewMode {
        case .pendingToBill:
            let groups = pendingByStudent.map { ($0.0, $0.1) }
            let csv = ExportService.makeFilteredPendingCSV(scope: exportScope, groups: groups)
            presentCSV(csv, filename: csvFilename(exportFilenameBase))
        case .issued:
            let groups = billsGroupedByStudent.map { ($0.0, $0.1) }
            let csv = ExportService.makeFilteredBillsCSV(scope: exportScope, groups: groups)
            presentCSV(csv, filename: csvFilename(exportFilenameBase))
        }
    }

    private var exportFilenameBase: String {
        var parts = [viewMode.title, timeRangeTitle]
        if let selectedStudentName {
            parts.append(selectedStudentName)
        } else {
            parts.append(String(localized: "全部学生"))
        }
        if viewMode == .issued {
            parts.append(statusFilter.title)
        }
        return parts.joined(separator: "_")
    }

    private func presentCSV(_ csv: String, filename: String) {
        do {
            shareItems = [try ShareService.temporaryCSVURL(from: csv, filename: filename)]
            showShareSheet = true
            AnalyticsService.exportCSV(source: "filter")
        } catch {
            shareError = error.localizedDescription
            showShareError = true
        }
    }

    private func csvFilename(_ base: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(ShareService.safeFilename(base))_\(formatter.string(from: .now)).csv"
    }

    private func syncExpandedStudents() {
        let ids = Set(billsGroupedByStudent.map(\.0.id))
        if expandedStudentIDs.isEmpty {
            expandedStudentIDs = ids
        } else {
            expandedStudentIDs.formUnion(ids)
        }
    }
}

struct CreateBillView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let student: Student
    let pendingLessons: [LessonRecord]

    @State private var selectedLessonIDs: Set<UUID>
    @State private var periodStart: Date
    @State private var periodEnd: Date
    @State private var note = ""
    @State private var errorMessage: String?
    @State private var showError = false

    init(student: Student, pendingLessons: [LessonRecord]) {
        self.student = student
        self.pendingLessons = pendingLessons
        _selectedLessonIDs = State(initialValue: Set(pendingLessons.map(\.id)))
        let dates = pendingLessons.map(\.date)
        _periodStart = State(initialValue: dates.min() ?? .now)
        _periodEnd = State(initialValue: dates.max() ?? .now)
    }

    private var selectedTotal: Int {
        pendingLessons.filter { selectedLessonIDs.contains($0.id) }.reduce(0) { $0 + $1.amountCents }
    }

    var body: some View {
        TLPageScaffold(title: String(localized: "生成账单"), subtitle: student.name, showBack: true) {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(TLColors.teal)
                        Text(String(localized: "将为 \(student.name) 生成一张账单，汇总所选课时。家长收到的是一张总账，不是每节课单独一张。"))
                            .font(.caption)
                            .foregroundStyle(TLColors.secondaryText)
                    }
                    .tlCard(padding: 12)

                    TLMoneyHero(
                        amount: MoneyFormat.display(cents: selectedTotal),
                        label: String(localized: "账单合计")
                    )
                    .tlCard(padding: 14)

                    TLFormCard(title: String(localized: "账期"), icon: "calendar") {
                        DatePicker("开始", selection: $periodStart, displayedComponents: .date)
                            .tint(TLColors.teal)
                        DatePicker("结束", selection: $periodEnd, displayedComponents: .date)
                            .tint(TLColors.teal)
                        TLTextInput(placeholder: String(localized: "备注（可选）"), text: $note)
                    }

                    TLFormCard(title: String(localized: "选择课时"), icon: "checklist") {
                        ForEach(pendingLessons) { lesson in
                            Button { toggleLesson(lesson.id) } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(TLDateFormat.monthDay(lesson.date))
                                            .foregroundStyle(TLColors.primaryText)
                                        Text("\(lesson.subject) · \(MoneyFormat.display(cents: lesson.amountCents))")
                                            .font(.caption)
                                            .foregroundStyle(TLColors.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: selectedLessonIDs.contains(lesson.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedLessonIDs.contains(lesson.id) ? TLColors.teal : TLColors.secondaryText)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button("生成账单") { createBill() }
                        .buttonStyle(TLPrimaryButtonStyle())
                        .disabled(selectedLessonIDs.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .tlKeyboardDismissibleScroll()
        }
        .alert("无法生成", isPresented: $showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func toggleLesson(_ id: UUID) {
        if selectedLessonIDs.contains(id) { selectedLessonIDs.remove(id) }
        else { selectedLessonIDs.insert(id) }
    }

    private func createBill() {
        let selected = pendingLessons.filter { selectedLessonIDs.contains($0.id) }
        do {
            _ = try BillingService.createBill(
                student: student,
                lessons: selected,
                periodStart: periodStart,
                periodEnd: periodEnd,
                note: note,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct BillDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var bill: Bill

    @State private var showMarkPaid = false
    @State private var showCancelConfirm = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var paymentMethod: PaymentMethod = .wechat
    @State private var paidAt = Date.now
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var toastMessage: String?

    private var sortedLessons: [LessonRecord] {
        bill.lessons.sorted { $0.date > $1.date }
    }

    var body: some View {
        TLPageScaffold(
            title: String(localized: "账单详情"),
            subtitle: bill.student?.name ?? "",
            showBack: true
        ) {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            TLStatusBadge(
                                text: bill.status.title,
                                color: bill.status == .paid ? TLColors.income : TLColors.pending
                            )
                            Spacer()
                            Text(bill.periodTitle)
                                .font(.caption)
                                .foregroundStyle(TLColors.secondaryText)
                        }
                        TLMoneyHero(amount: MoneyFormat.display(cents: bill.totalAmountCents))
                        TLDetailRow(
                            label: String(localized: "包含课时"),
                            value: String(localized: "\(bill.lessons.count) 节")
                        )
                        if let paidAt = bill.paidAt {
                            TLDetailRow(
                                label: String(localized: "收款日期"),
                                value: TLDateFormat.mediumDateTime(paidAt)
                            )
                        }
                        if let method = bill.paymentMethod {
                            TLDetailRow(label: String(localized: "收款方式"), value: method.title)
                        }
                    }
                    .tlCard()

                    TLFormCard(title: String(localized: "课时明细"), icon: "list.bullet") {
                        ForEach(sortedLessons) { lesson in
                            NavigationLink {
                                LessonDetailView(lesson: lesson)
                            } label: {
                                LessonRowView(lesson: lesson)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        copyBillText()
                    } label: {
                        Label("复制文字给家长", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TLPrimaryButtonStyle())

                    Button {
                        shareBillCSV()
                    } label: {
                        Label("分享 CSV", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TLSecondaryButtonStyle())

                    if bill.status == .draft {
                        Button("标记为已发送") { markSent() }
                            .buttonStyle(TLSecondaryButtonStyle())
                    }
                    if bill.status != .paid {
                        Button("标记已收款") { showMarkPaid = true }
                            .buttonStyle(TLPrimaryButtonStyle())

                        Button("撤销账单") { showCancelConfirm = true }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(TLColors.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .tlKeyboardDismissibleScroll()
        }
        .confirmationDialog("撤销账单？", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("撤销并退回待收", role: .destructive) { cancelBill() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("账单将被删除，所含课时恢复为「待结算」状态。")
        }
        .activityShareSheet(isPresented: $showShareSheet, items: shareItems)
        .sheet(isPresented: $showMarkPaid) {
            TLMarkPaidSheet(paymentMethod: $paymentMethod, paidAt: $paidAt) {
                markPaid()
            }
        }
        .alert("操作失败", isPresented: $showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .tlToast($toastMessage)
    }

    private func markSent() {
        do { try BillingService.markBillSent(bill, context: modelContext) }
        catch { errorMessage = error.localizedDescription; showError = true }
    }

    private func markPaid() {
        do {
            try BillingService.markBillPaid(bill, paymentMethod: paymentMethod, paidAt: paidAt, context: modelContext)
            showMarkPaid = false
        } catch { errorMessage = error.localizedDescription; showError = true }
    }

    private func cancelBill() {
        do {
            try BillingService.cancelBill(bill, context: modelContext)
            dismiss()
        } catch { errorMessage = error.localizedDescription; showError = true }
    }

    private func shareBillCSV() {
        do {
            let csv = ExportService.makeBillCSV(bill: bill)
            let name = bill.student?.name ?? String(localized: "学生")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let billSuffix = String(localized: "_账单")
            let filename = "\(ShareService.safeFilename("\(name)\(billSuffix)"))_\(formatter.string(from: .now)).csv"
            shareItems = [try ShareService.temporaryCSVURL(from: csv, filename: filename)]
            showShareSheet = true
            AnalyticsService.exportCSV(source: "bill")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func copyBillText() {
        UIPasteboard.general.string = ExportService.makeBillShareText(bill: bill)
        toastMessage = String(localized: "已复制，可粘贴到微信发给家长")
    }
}
