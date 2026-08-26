import SwiftData
import SwiftUI

struct PackagePurchaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let student: Student

    @State private var hoursText = "10"
    @State private var amountText = ""
    @State private var note = ""
    @State private var errorMessage: String?
    @State private var showError = false

    private var remainingAfter: Int {
        student.packageRemainingHours + (Int(hoursText) ?? 0)
    }

    var body: some View {
        TLPageScaffold(
            title: String(localized: "购课 / 续费"),
            subtitle: student.name,
            showBack: true,
            leadingTitle: String(localized: "取消"),
            trailingTitle: String(localized: "保存"),
            onLeading: { dismiss() },
            onTrailing: { save() }
        ) {
            ScrollView {
                VStack(spacing: 16) {
                    TLMoneyHero(
                        amount: String(localized: "\(remainingAfter) 节"),
                        label: String(localized: "购课后剩余课时"),
                        gradient: TLColors.accentGradient
                    )
                    .tlCard(padding: 14)

                    TLFormCard(title: String(localized: "购课信息"), icon: "ticket.fill") {
                        TLFormRow(label: String(localized: "购买节数")) {
                            TLTextInput(placeholder: "10", text: $hoursText, keyboard: .numberPad)
                        }
                        TLFormRow(label: String(localized: "实收金额（可选）")) {
                            HStack {
                                TLTextInput(placeholder: "0", text: $amountText, keyboard: .decimalPad)
                                Text(AppSettings.currencySymbol)
                                    .foregroundStyle(TLColors.secondaryText)
                            }
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
        .alert("无法保存", isPresented: $showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func save() {
        guard let hours = Int(hoursText), hours > 0 else {
            errorMessage = String(localized: "请输入有效节数")
            showError = true
            return
        }

        let amountCents: Int? = {
            guard !amountText.isEmpty, let value = Double(amountText) else { return nil }
            return MoneyFormat.yuanToCents(Decimal(value))
        }()

        do {
            _ = try BillingService.purchasePackage(
                student: student,
                hours: hours,
                amountCents: amountCents,
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
