import Foundation
import SwiftData

@Model
final class LessonRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var durationHours: Double
    var subject: String
    var unitPriceCents: Int
    var amountCents: Int
    var typeRaw: String
    var billingStatusRaw: String
    var note: String
    var voidReason: String?
    var paymentMethodRaw: String?
    var paidAt: Date?
    var createdAt: Date
    var updatedAt: Date

    var student: Student?
    var bill: Bill?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        durationHours: Double,
        subject: String,
        unitPriceCents: Int,
        amountCents: Int,
        type: LessonType = .normal,
        billingStatus: LessonBillingStatus,
        note: String = "",
        voidReason: String? = nil,
        paymentMethod: PaymentMethod? = nil,
        paidAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        student: Student? = nil,
        bill: Bill? = nil
    ) {
        self.id = id
        self.date = date
        self.durationHours = durationHours
        self.subject = subject
        self.unitPriceCents = unitPriceCents
        self.amountCents = amountCents
        self.typeRaw = type.rawValue
        self.billingStatusRaw = billingStatus.rawValue
        self.note = note
        self.voidReason = voidReason
        self.paymentMethodRaw = paymentMethod?.rawValue
        self.paidAt = paidAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.student = student
        self.bill = bill
    }

    var type: LessonType {
        get { LessonType(rawValue: typeRaw) ?? .normal }
        set { typeRaw = newValue.rawValue }
    }

    var billingStatus: LessonBillingStatus {
        get { LessonBillingStatus(rawValue: billingStatusRaw) ?? .pending }
        set { billingStatusRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod? {
        get {
            guard let raw = paymentMethodRaw else { return nil }
            return PaymentMethod(rawValue: raw)
        }
        set { paymentMethodRaw = newValue?.rawValue }
    }

    var isEditable: Bool {
        billingStatus == .pending || billingStatus == .deducted
    }

    var isVoidable: Bool {
        billingStatus == .pending || billingStatus == .deducted
    }
}
