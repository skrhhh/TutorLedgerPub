import Foundation
import SwiftData

@Model
final class Bill {
    @Attribute(.unique) var id: UUID
    var periodStart: Date
    var periodEnd: Date
    var totalAmountCents: Int
    var statusRaw: String
    var paidAt: Date?
    var paymentMethodRaw: String?
    var note: String
    var createdAt: Date
    var updatedAt: Date

    var student: Student?

    @Relationship(deleteRule: .nullify, inverse: \LessonRecord.bill)
    var lessons: [LessonRecord]

    init(
        id: UUID = UUID(),
        periodStart: Date,
        periodEnd: Date,
        totalAmountCents: Int = 0,
        status: BillStatus = .draft,
        paidAt: Date? = nil,
        paymentMethod: PaymentMethod? = nil,
        note: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        student: Student? = nil,
        lessons: [LessonRecord] = []
    ) {
        self.id = id
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.totalAmountCents = totalAmountCents
        self.statusRaw = status.rawValue
        self.paidAt = paidAt
        self.paymentMethodRaw = paymentMethod?.rawValue
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.student = student
        self.lessons = lessons
    }

    var status: BillStatus {
        get { BillStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod? {
        get {
            guard let raw = paymentMethodRaw else { return nil }
            return PaymentMethod(rawValue: raw)
        }
        set { paymentMethodRaw = newValue?.rawValue }
    }

    var periodTitle: String {
        "\(TLDateFormat.mediumDate(periodStart)) – \(TLDateFormat.mediumDate(periodEnd))"
    }
}
