import SwiftData
import SwiftUI

struct QuickAddStudentSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onCreated: (Student) -> Void

    @State private var name = ""
    @State private var billingMode: BillingMode = .postpaid
    @State private var unitPriceText = "200"
    @State private var packageHoursText = "10"
    @State private var subjectsText = ""
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
            title: String(localized: "添加学生"),
            showBack: true,
            leadingTitle: String(localized: "取消"),
            trailingTitle: String(localized: "保存"),
            trailingEnabled: canSave,
            onLeading: { dismiss() },
            onTrailing: { attemptSave() }
        ) {
            ScrollView {
                VStack(spacing: 16) {
                    Text("快速添加后可立即记课时，详细资料可在学生页补充。")
                        .font(.caption)
                        .foregroundStyle(TLColors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tlCard(padding: 12)

                    TLFormCard(title: String(localized: "基本信息"), icon: "person.fill") {
                        TLFormRow(label: String(localized: "姓名/昵称")) {
                            TLTextInput(placeholder: String(localized: "小明"), text: $name)
                        }
                        TLFormRow(label: String(localized: "科目（可选）")) {
                            TLTextInput(placeholder: String(localized: "数学"), text: $subjectsText)
                        }
                    }

                    TLFormCard(title: String(localized: "计费"), icon: "yensign.circle") {
                        TLFormRow(label: String(localized: "计费模式")) {
                            TLChipSelector(
                                items: Array(BillingMode.allCases),
                                selection: $billingMode,
                                title: \.title
                            )
                        }
                        TLFormRow(label: String(format: String(localized: "默认单价（%@）"), AppSettings.unitPriceLabel)) {
                            TLTextInput(placeholder: "200", text: $unitPriceText, keyboard: .decimalPad)
                        }
                        if billingMode == .prepaid {
                            TLFormRow(label: String(localized: "课包节数")) {
                                TLTextInput(placeholder: "10", text: $packageHoursText, keyboard: .numberPad)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .tlKeyboardDismissibleScroll()
        }
        .confirmationDialog("科目未填写", isPresented: $showSubjectsConfirm, titleVisibility: .visible) {
            Button("直接保存") { performSave() }
            Button("返回填写", role: .cancel) {}
        } message: {
            Text("未填写科目不影响保存，但记课时时需要手动输入科目。是否直接保存？")
        }
        .tlToast($toastMessage)
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

        let unitCents = parsedUnitPriceCents ?? MoneyFormat.yuanToCents(Decimal(200))
        let packageHours = billingMode == .prepaid
            ? (Int(packageHoursText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
            : 0

        let student = Student(
            name: trimmedName,
            subjects: subjects,
            billingMode: billingMode,
            defaultUnitPriceCents: unitCents,
            packageTotalHours: packageHours,
            packageRemainingHours: packageHours
        )
        modelContext.insert(student)
        if BillingService.insertOpeningPackage(student: student, hours: packageHours, context: modelContext) != nil {
            AnalyticsService.packagePurchase(hours: packageHours, source: "opening", hasAmount: false)
        }
        do {
            try modelContext.save()
            AnalyticsService.addStudent(
                billingMode: billingMode,
                source: "quick_add",
                packageHours: packageHours
            )
            onCreated(student)
            dismiss()
        } catch {
            toastMessage = error.localizedDescription
            AnalyticsService.recordError(error, context: "quick_add_student")
        }
    }

    private var parsedUnitPriceCents: Int? {
        let trimmed = unitPriceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Double(trimmed), value >= 0 else { return nil }
        return MoneyFormat.yuanToCents(Decimal(value))
    }
}
