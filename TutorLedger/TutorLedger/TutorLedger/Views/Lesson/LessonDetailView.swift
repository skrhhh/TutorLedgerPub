import SwiftData
import SwiftUI

struct LessonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var lesson: LessonRecord

    @State private var isEditing = false
    @State private var date = Date.now
    @State private var durationHours = 2.0
    @State private var subject = ""
    @State private var unitPriceText = ""
    @State private var lessonType: LessonType = .normal
    @State private var note = ""
    @State private var showVoidSheet = false
    @State private var showMarkPaid = false
    @State private var voidReason = ""
    @State private var paymentMethod: PaymentMethod = .wechat
    @State private var paidAt = Date.now
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var toastMessage: String?

    var body: some View {
        TLPageScaffold(
            title: String(localized: "课时详情"),
            subtitle: lesson.student?.name,
            showBack: true,
            trailingTitle: lesson.isEditable
                ? (isEditing ? String(localized: "完成") : String(localized: "编辑"))
                : nil,
            onTrailing: lesson.isEditable ? {
                if isEditing { saveEdits() } else { loadEditState(); isEditing = true }
            } : nil
        ) {
            ScrollView {
                VStack(spacing: 16) {
                    TLMoneyHero(
                        amount: MoneyFormat.display(cents: lesson.amountCents),
                        label: lesson.subject,
                        gradient: TLColors.breezeGradient
                    )
                    .tlCard(padding: 14)

                    if isEditing {
                        TLFormCard(title: String(localized: "编辑"), icon: "pencil") {
                            DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .tint(TLColors.teal)
                            TLFormRow(label: String(localized: "时长")) {
                                TLDurationPicker(hours: $durationHours)
                            }
                            TLTextInput(placeholder: String(localized: "科目"), text: $subject)
                            TLTextInput(placeholder: String(localized: "单价"), text: $unitPriceText, keyboard: .decimalPad)
                            TLChipSelector(items: Array(LessonType.allCases), selection: $lessonType, title: \.title)
                            TLTextInput(placeholder: String(localized: "备注"), text: $note)
                        }
                    } else {
                        TLFormCard(title: String(localized: "详情"), icon: "info.circle") {
                            TLDetailRow(
                                label: String(localized: "学生"),
                                value: lesson.student?.name ?? "—"
                            )
                            TLDetailRow(
                                label: String(localized: "日期"),
                                value: TLDateFormat.mediumDateTime(lesson.date)
                            )
                            TLDetailRow(
                                label: String(localized: "时长"),
                                value: MoneyFormat.display(hours: lesson.durationHours)
                            )
                            TLDetailRow(
                                label: String(localized: "单价"),
                                value: String(format: String(localized: "%@/小时"), MoneyFormat.display(cents: lesson.unitPriceCents))
                            )
                            TLDetailRow(label: String(localized: "类型"), value: lesson.type.title)
                            TLDetailRow(
                                label: String(localized: "状态"),
                                value: lesson.billingStatus.title,
                                valueColor: statusColor
                            )
                            if let paidAt = lesson.paidAt {
                                TLDetailRow(
                                    label: String(localized: "收款日期"),
                                    value: TLDateFormat.mediumDateTime(paidAt)
                                )
                            }
                            if let method = lesson.paymentMethod {
                                TLDetailRow(label: String(localized: "收款方式"), value: method.title)
                            }
                            if !lesson.note.isEmpty {
                                TLDetailRow(label: String(localized: "备注"), value: lesson.note)
                            }
                            if let voidReason = lesson.voidReason {
                                TLDetailRow(label: String(localized: "作废原因"), value: voidReason)
                            }
                        }
                    }

                    if lesson.billingStatus == .pending {
                        Button("标记已收款") { paidAt = .now; showMarkPaid = true }
                            .buttonStyle(TLPrimaryButtonStyle())
                    }

                    if lesson.isVoidable {
                        Button("作废此课时") {
                            voidReason = ""
                            showVoidSheet = true
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TLColors.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    } else if lesson.billingStatus != .void {
                        Text("已出账或已收款的课时不能直接作废。如需更正，请先撤销对应账单。")
                            .font(.caption)
                            .foregroundStyle(TLColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .tlKeyboardDismissibleScroll()
        }
        .sheet(isPresented: $showVoidSheet) {
            VoidLessonSheet(reason: $voidReason) { reason in
                voidLesson(reason: reason)
            }
        }
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

    private var statusColor: Color {
        switch lesson.billingStatus {
        case .paid, .deducted: TLColors.income
        case .pending, .billed: TLColors.pending
        case .void: TLColors.secondaryText
        }
    }

    private func loadEditState() {
        date = lesson.date
        durationHours = lesson.durationHours
        subject = lesson.subject
        unitPriceText = String(format: "%.0f", Double(lesson.unitPriceCents) / 100.0)
        lessonType = lesson.type
        note = lesson.note
    }

    private func saveEdits() {
        let unitCents = MoneyFormat.yuanToCents(Decimal(Double(unitPriceText) ?? 0))
        do {
            try BillingService.updateLesson(
                lesson, date: date, durationHours: durationHours, subject: subject,
                unitPriceCents: unitCents, lessonType: lessonType, note: note, context: modelContext
            )
            isEditing = false
        } catch { errorMessage = error.localizedDescription; showError = true }
    }

    private func voidLesson(reason: String) {
        do {
            try BillingService.voidLesson(lesson, reason: reason, context: modelContext)
            showVoidSheet = false
            toastMessage = String(localized: "已作废该课时")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                dismiss()
            }
        } catch {
            showVoidSheet = false
            errorMessage = error.localizedDescription
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showError = true
            }
        }
    }

    private func markPaid() {
        do {
            try BillingService.markLessonPaid(
                lesson,
                paymentMethod: paymentMethod,
                paidAt: paidAt,
                context: modelContext
            )
            showMarkPaid = false
        } catch { errorMessage = error.localizedDescription; showError = true }
    }
}

private struct VoidLessonSheet: View {
    @Binding var reason: String
    let onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private var trimmedReason: String {
        reason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            TLTopBar(
                title: String(localized: "作废课时"),
                showBack: true,
                onLeading: { dismiss() }
            )
            VStack(alignment: .leading, spacing: 16) {
                TLTextInput(placeholder: String(localized: "作废原因，例如学生请假"), text: $reason)
                if trimmedReason.isEmpty {
                    Text("填写原因后即可确认。作废后课时不再计入统计，先付课包会返还 1 节。")
                        .font(.caption)
                        .foregroundStyle(TLColors.secondaryText)
                }
                Button("确认作废") {
                    KeyboardDismiss.dismiss()
                    onConfirm(trimmedReason)
                }
                .buttonStyle(TLPrimaryButtonStyle())
                .disabled(trimmedReason.isEmpty)
            }
            .padding(20)
            Spacer()
        }
        .tlScreenBackground()
        .presentationDetents([.medium])
        .installKeyboardDismissOnTap()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") { KeyboardDismiss.dismiss() }
                    .foregroundStyle(TLColors.teal)
            }
        }
    }
}
