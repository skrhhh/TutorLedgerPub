import SwiftData
import SwiftUI

struct LogLessonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Student> { $0.statusRaw == "active" }, sort: \Student.name)
    private var activeStudents: [Student]

    var preselectedStudent: Student?

    @State private var selectedStudent: Student?
    @State private var date = Date.now
    @State private var durationHours: Double = AppSettings.defaultDurationHours
    @State private var subject = ""
    @State private var unitPriceText = ""
    @State private var lessonType: LessonType = .normal
    @State private var note = ""
    @State private var markPaidImmediately = false
    @State private var showMarkPaidSheet = false
    @State private var showQuickAddStudent = false
    @State private var showSubjectConfirm = false
    @State private var paymentMethod: PaymentMethod = .wechat
    @State private var paidAt = Date.now
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var toastMessage: String?

    private enum SaveValidation {
        case ready
        case subjectMissing
        case blocked(reasons: [String])
    }

    private var saveValidation: SaveValidation {
        var blocked: [String] = []

        guard let student = selectedStudent else {
            blocked.append(String(localized: "请选择学生"))
            return .blocked(reasons: blocked)
        }

        if student.billingMode == .prepaid, lessonType != .free, student.packageRemainingHours <= 0 {
            blocked.append(String(localized: "课包剩余课时不足"))
        }

        if durationHours <= 0 {
            blocked.append(String(localized: "请设置上课时长"))
        }

        if !blocked.isEmpty {
            return .blocked(reasons: blocked)
        }

        if subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .subjectMissing
        }

        return .ready
    }

    private var canSave: Bool {
        if case .blocked = saveValidation { return false }
        return true
    }

    var body: some View {
        TLPageScaffold(
            title: String(localized: "记课时"),
            showBack: true,
            leadingTitle: String(localized: "取消"),
            trailingTitle: String(localized: "保存"),
            trailingEnabled: canSave,
            onLeading: { dismiss() },
            onTrailing: { attemptSave() }
        ) {
            ScrollView {
                VStack(spacing: 16) {
                    studentPickerCard

                    TLFormCard(title: String(localized: "上课信息"), icon: "clock.fill") {
                        TLFormRow(label: String(localized: "日期时间")) {
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .tint(TLColors.teal)
                        }
                        TLFormRow(label: String(localized: "时长")) {
                            TLDurationPicker(
                                hours: $durationHours,
                                presets: studentDurationPresets
                            )
                        }
                        TLFormRow(label: String(localized: "科目")) {
                            TLTextInput(placeholder: subjectPlaceholder, text: $subject)
                        }
                        TLFormRow(label: String(format: String(localized: "本次单价（%@）"), AppSettings.unitPriceLabel)) {
                            TLTextInput(placeholder: "200", text: $unitPriceText, keyboard: .decimalPad)
                        }
                        TLFormRow(label: String(localized: "课时类型")) {
                            TLChipSelector(
                                items: Array(LessonType.allCases),
                                selection: $lessonType,
                                title: \.title
                            )
                        }
                        TLFormRow(label: String(localized: "备注")) {
                            TLTextInput(placeholder: String(localized: "可选"), text: $note)
                        }
                    }

                    if selectedStudent?.billingMode == .perSession {
                        TLFormCard(title: String(localized: "收款"), icon: "yensign.circle") {
                            Toggle("当场已收款", isOn: $markPaidImmediately)
                                .tint(TLColors.teal)
                        }
                    }

                    if let student = selectedStudent {
                        TLFormCard(title: String(localized: "预计结果"), icon: "sparkles") {
                            let unitCents = parsedUnitPriceCents(fallback: student.defaultUnitPriceCents)
                            let amount = BillingService.calculateAmountCents(
                                unitPriceCents: unitCents,
                                durationHours: durationHours,
                                lessonType: lessonType
                            )
                            TLDetailRow(
                                label: String(localized: "金额"),
                                value: MoneyFormat.display(cents: amount),
                                valueColor: TLColors.income
                            )
                            TLDetailRow(label: String(localized: "计费方式"), value: student.billingMode.title)
                            if student.billingMode == .prepaid {
                                let remaining = max(0, student.packageRemainingHours - (lessonType == .free ? 0 : 1))
                                TLDetailRow(
                                    label: String(localized: "扣课后剩余"),
                                    value: String(localized: "\(remaining) 节")
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .tlKeyboardDismissibleScroll()
        }
        .onAppear {
            durationHours = preselectedStudent?.defaultDurationHours ?? AppSettings.defaultDurationHours
            if let preselectedStudent { selectedStudent = preselectedStudent }
            applyStudentDefaults()
        }
        .sheet(isPresented: $showQuickAddStudent) {
            QuickAddStudentSheet { student in
                selectedStudent = student
                applyStudentDefaults()
            }
        }
        .sheet(isPresented: $showMarkPaidSheet) {
            TLMarkPaidSheet(paymentMethod: $paymentMethod, paidAt: $paidAt) {
                performSave()
            }
        }
        .confirmationDialog("科目未填写", isPresented: $showSubjectConfirm, titleVisibility: .visible) {
            Button("直接保存") { proceedSave() }
            Button("返回填写", role: .cancel) {}
        } message: {
            Text(subjectConfirmMessage)
        }
        .alert("无法保存", isPresented: $showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage ?? String(localized: "未知错误"))
        }
        .tlToast($toastMessage)
    }

    private var studentPickerCard: some View {
        TLFormCard(title: String(localized: "选择学生"), icon: "person.fill") {
            FlowLayout(spacing: 8) {
                addStudentChip

                ForEach(activeStudents) { student in
                    studentChip(student)
                }
            }

            if activeStudents.isEmpty {
                Text("还没有在读学生，点「新学生」快速添加")
                    .font(.caption)
                    .foregroundStyle(TLColors.secondaryText)
                    .padding(.top, 4)
            } else if selectedStudent == nil {
                Text("请选择一位学生")
                    .font(.caption)
                    .foregroundStyle(TLColors.pending)
                    .padding(.top, 4)
            }
        }
    }

    private var addStudentChip: some View {
        Button {
            showQuickAddStudent = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.caption.weight(.bold))
                Text("新学生")
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(TLColors.softFillGradient)
            .overlay {
                Capsule()
                    .strokeBorder(TLColors.teal.opacity(0.45), lineWidth: 1)
            }
            .foregroundStyle(TLColors.teal)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func studentChip(_ student: Student) -> some View {
        Button {
            selectedStudent = student
            applyStudentDefaults()
        } label: {
            HStack(spacing: 6) {
                TLAvatarView(name: student.name, size: 28)
                Text(student.name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if selectedStudent?.id == student.id {
                    TLColors.breezeGradient
                } else {
                    TLColors.softFillGradient
                }
            }
            .overlay {
                if selectedStudent?.id != student.id {
                    Capsule()
                        .strokeBorder(TLColors.tealLight.opacity(0.35), lineWidth: 1)
                }
            }
            .foregroundStyle(selectedStudent?.id == student.id ? .white : TLColors.primaryText)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var subjectPlaceholder: String {
        if let student = selectedStudent, student.hasSubjects {
            return student.primarySubject
        }
        return String(localized: "数学")
    }

    private var subjectConfirmMessage: String {
        guard let student = selectedStudent else {
            return String(localized: "未填写科目，是否仍要保存？")
        }
        if student.hasSubjects {
            return String(localized: "未填写本科目，保存后将使用「\(student.primarySubject)」。是否直接保存？")
        }
        return String(localized: "未填写科目，是否仍要保存？")
    }

    private var studentDurationPresets: [Double] {
        guard let student = selectedStudent else { return AppSettings.durationPresets }
        var presets = AppSettings.durationPresets
        if !presets.contains(where: { abs($0 - student.defaultDurationHours) < 0.001 }) {
            presets.append(student.defaultDurationHours)
            presets.sort()
        }
        return presets
    }

    private func applyStudentDefaults() {
        guard let student = selectedStudent else { return }
        if subject.isEmpty {
            subject = student.hasSubjects ? student.primarySubject : ""
        }
        unitPriceText = String(format: "%.0f", Double(student.defaultUnitPriceCents) / 100.0)
        durationHours = student.defaultDurationHours
    }

    private func attemptSave() {
        switch saveValidation {
        case .blocked(let reasons):
            toastMessage = reasons.joined(separator: "；")
        case .subjectMissing:
            showSubjectConfirm = true
        case .ready:
            proceedSave()
        }
    }

    private func proceedSave() {
        if markPaidImmediately {
            paidAt = date
            showMarkPaidSheet = true
        } else {
            performSave()
        }
    }

    private func performSave() {
        guard let student = selectedStudent else { return }
        let unitCents = parsedUnitPriceCents(fallback: student.defaultUnitPriceCents)
        let trimmed = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        // Persist raw subject text only — never store a localized placeholder.
        let resolvedSubject = trimmed.isEmpty ? (student.subjects.first ?? "") : trimmed
        do {
            _ = try BillingService.logLesson(
                student: student,
                date: date,
                durationHours: durationHours,
                subject: resolvedSubject,
                unitPriceCents: unitCents,
                lessonType: lessonType,
                note: note,
                markPaidImmediately: markPaidImmediately,
                paymentMethod: markPaidImmediately ? paymentMethod : nil,
                paidAt: markPaidImmediately ? paidAt : nil,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func parsedUnitPriceCents(fallback: Int) -> Int {
        let trimmed = unitPriceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed) else { return fallback }
        return MoneyFormat.yuanToCents(Decimal(value))
    }
}
