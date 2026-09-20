import SwiftData
import SwiftUI

struct AddEditStudentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var student: Student?

    @State private var name = ""
    @State private var grade: GradeLevel = .junior
    @State private var subjectsText = ""
    @State private var billingMode: BillingMode = .postpaid
    @State private var unitPriceText = "200"
    @State private var packageHoursText = "20"
    @State private var settlementCycle: SettlementCycle = .monthly
    @State private var status: StudentStatus = .active
    @State private var note = ""
    @State private var defaultDurationHours = AppSettings.defaultDurationHours
    @State private var nextLessonAt = Date.now
    @State private var hasNextLesson = false
    @State private var showSubjectsConfirm = false
    @State private var toastMessage: String?

    private enum SaveValidation {
        case ready
        case subjectsMissing
        case blocked(reasons: [String])
    }

    private var saveValidation: SaveValidation {
        var blocked: [String] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            blocked.append(String(localized: "请填写姓名"))
        }

        if parsedUnitPriceCents == nil {
            blocked.append(String(localized: "请填写默认单价"))
        }

        if billingMode == .prepaid {
            let hours = Int(packageHoursText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            if hours <= 0 {
                blocked.append(String(localized: "请填写课包节数"))
            }
        }

        if defaultDurationHours <= 0 {
            blocked.append(String(localized: "请设置默认时长"))
        }

        if !blocked.isEmpty {
            return .blocked(reasons: blocked)
        }

        if subjectsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .subjectsMissing
        }

        return .ready
    }

    private var canSave: Bool {
        if case .blocked = saveValidation { return false }
        return true
    }

    var body: some View {
        TLPageScaffold(
            title: student == nil ? String(localized: "添加学生") : String(localized: "编辑学生"),
            showBack: true,
            leadingTitle: String(localized: "取消"),
            trailingTitle: String(localized: "保存"),
            trailingEnabled: canSave,
            onLeading: { dismiss() },
            onTrailing: { attemptSave() }
        ) {
            ScrollView {
                VStack(spacing: 16) {
                    TLFormCard(title: String(localized: "基本信息"), icon: "person.fill") {
                        TLFormRow(label: String(localized: "姓名/昵称")) {
                            TLTextInput(placeholder: String(localized: "小明-初二数学"), text: $name)
                        }
                        TLFormRow(label: String(localized: "年级")) {
                            TLChipSelector(items: Array(GradeLevel.allCases), selection: $grade, title: \.title)
                        }
                        TLFormRow(label: String(localized: "科目（顿号分隔）")) {
                            TLTextInput(placeholder: String(localized: "数学、英语"), text: $subjectsText)
                        }
                        TLFormRow(label: String(localized: "状态")) {
                            TLChipSelector(items: Array(StudentStatus.allCases), selection: $status, title: \.title)
                        }
                    }

                    TLFormCard(title: String(localized: "计费设置"), icon: "yensign.circle") {
                        TLFormRow(label: String(localized: "计费模式")) {
                            TLChipSelector(items: Array(BillingMode.allCases), selection: $billingMode, title: \.title)
                        }
                        TLFormRow(label: String(format: String(localized: "默认单价（%@）"), AppSettings.unitPriceLabel)) {
                            TLTextInput(placeholder: "200", text: $unitPriceText, keyboard: .decimalPad)
                        }
                        if billingMode == .prepaid {
                            TLFormRow(label: String(localized: "课包节数")) {
                                TLTextInput(placeholder: "20", text: $packageHoursText, keyboard: .numberPad)
                            }
                        }
                        if billingMode == .postpaid {
                            TLFormRow(label: String(localized: "结算周期")) {
                                TLChipSelector(items: Array(SettlementCycle.allCases), selection: $settlementCycle, title: \.title)
                            }
                        }
                        TLFormRow(label: String(localized: "默认时长")) {
                            TLDurationPicker(hours: $defaultDurationHours)
                        }
                    }

                    TLFormCard(title: String(localized: "其他"), icon: "note.text") {
                        Toggle("设置下次上课时间", isOn: $hasNextLesson)
                            .tint(TLColors.teal)
                        if hasNextLesson {
                            DatePicker("", selection: $nextLessonAt)
                                .labelsHidden()
                                .tint(TLColors.teal)
                        }
                        TLFormRow(label: String(localized: "备注")) {
                            TLTextInput(placeholder: String(localized: "可选"), text: $note)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .tlKeyboardDismissibleScroll()
        }
        .onAppear { loadStudent() }
        .confirmationDialog("科目未填写", isPresented: $showSubjectsConfirm, titleVisibility: .visible) {
            Button("直接保存") { performSave() }
            Button("返回填写", role: .cancel) {}
        } message: {
            Text("未填写科目不影响保存，但记课时时需要手动输入科目。是否直接保存？")
        }
        .tlToast($toastMessage)
    }

    private func loadStudent() {
        guard let student else { return }
        name = student.name
        grade = student.grade
        subjectsText = student.subjectsRaw
        billingMode = student.billingMode
        unitPriceText = String(format: "%.0f", Double(student.defaultUnitPriceCents) / 100.0)
        packageHoursText = String(student.packageTotalHours)
        settlementCycle = student.settlementCycle
        status = student.status
        note = student.note
        defaultDurationHours = student.defaultDurationHours
        if let next = student.nextLessonAt {
            hasNextLesson = true
            nextLessonAt = next
        }
    }

    private func attemptSave() {
        switch saveValidation {
        case .blocked(let reasons):
            toastMessage = reasons.joined(separator: "；")
        case .subjectsMissing:
            showSubjectsConfirm = true
        case .ready:
            performSave()
        }
    }

    private func performSave() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let subjects = subjectsText
            .split(separator: "、")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { String($0) }

        let unitCents = parsedUnitPriceCents ?? 0
        let packageHours = Int(packageHoursText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let isCreating = student == nil
        var recordedOpeningHours = 0

        if let student {
            let wasPrepaid = student.billingMode == .prepaid
            student.name = trimmedName
            student.grade = grade
            student.subjectsRaw = subjects.joined(separator: "、")
            student.billingMode = billingMode
            student.defaultUnitPriceCents = unitCents
            student.settlementCycle = settlementCycle
            student.status = status
            student.note = note
            student.defaultDurationHours = defaultDurationHours
            student.nextLessonAt = hasNextLesson ? nextLessonAt : nil
            student.updatedAt = .now
            if billingMode == .prepaid, !wasPrepaid || student.packageTotalHours == 0 {
                student.packageTotalHours = packageHours
                student.packageRemainingHours = packageHours
                if student.packageTransactions.isEmpty {
                    BillingService.insertOpeningPackage(student: student, hours: packageHours, context: modelContext)
                }
            }
        } else {
            let created = Student(
                name: trimmedName,
                grade: grade,
                subjects: subjects,
                billingMode: billingMode,
                defaultUnitPriceCents: unitCents,
                packageTotalHours: billingMode == .prepaid ? packageHours : 0,
                packageRemainingHours: billingMode == .prepaid ? packageHours : 0,
                settlementCycle: settlementCycle,
                status: status,
                note: note,
                nextLessonAt: hasNextLesson ? nextLessonAt : nil,
                defaultDurationHours: defaultDurationHours
            )
            modelContext.insert(created)
            if BillingService.insertOpeningPackage(student: created, hours: packageHours, context: modelContext) != nil {
                recordedOpeningHours = packageHours
            }
        }

        do {
            try modelContext.save()
            if isCreating {
                AnalyticsService.addStudent(
                    billingMode: billingMode,
                    source: "form",
                    packageHours: billingMode == .prepaid ? packageHours : 0
                )
                if recordedOpeningHours > 0 {
                    AnalyticsService.packagePurchase(
                        hours: recordedOpeningHours,
                        source: "opening",
                        hasAmount: false
                    )
                }
            }
            dismiss()
        } catch {
            toastMessage = error.localizedDescription
            AnalyticsService.recordError(error, context: "save_student")
        }
    }

    private var parsedUnitPriceCents: Int? {
        let trimmed = unitPriceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Double(trimmed), value >= 0 else { return nil }
        return MoneyFormat.yuanToCents(Decimal(value))
    }
}
