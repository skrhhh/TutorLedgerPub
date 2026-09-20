import Foundation
import SwiftData

enum BillingService {
    static func calculateAmountCents(
        unitPriceCents: Int,
        durationHours: Double,
        lessonType: LessonType
    ) -> Int {
        switch lessonType {
        case .free:
            return 0
        case .trial:
            return Int((Double(unitPriceCents) * durationHours * 0.5).rounded())
        default:
            return Int((Double(unitPriceCents) * durationHours).rounded())
        }
    }

    @discardableResult
    static func logLesson(
        student: Student,
        date: Date,
        durationHours: Double,
        subject: String,
        unitPriceCents: Int,
        lessonType: LessonType,
        note: String,
        markPaidImmediately: Bool,
        paymentMethod: PaymentMethod? = nil,
        paidAt: Date? = nil,
        context: ModelContext
    ) throws -> LessonRecord {
        let amountCents = calculateAmountCents(
            unitPriceCents: unitPriceCents,
            durationHours: durationHours,
            lessonType: lessonType
        )

        let billingStatus: LessonBillingStatus
        switch student.billingMode {
        case .prepaid:
            guard student.packageRemainingHours > 0 || lessonType == .free else {
                throw BillingError.insufficientPackageHours
            }
            billingStatus = .deducted
        case .postpaid:
            billingStatus = .pending
        case .perSession:
            billingStatus = markPaidImmediately ? .paid : .pending
        }

        let record = LessonRecord(
            date: date,
            durationHours: durationHours,
            subject: subject,
            unitPriceCents: unitPriceCents,
            amountCents: amountCents,
            type: lessonType,
            billingStatus: billingStatus,
            note: note,
            paymentMethod: markPaidImmediately ? (paymentMethod ?? .wechat) : nil,
            paidAt: markPaidImmediately ? (paidAt ?? date) : nil,
            student: student
        )
        context.insert(record)
        student.updatedAt = .now

        if student.billingMode == .prepaid, lessonType != .free {
            student.packageRemainingHours = max(0, student.packageRemainingHours - 1)
            let transaction = PackageTransaction(
                type: .deduct,
                hours: 1,
                note: "上课扣课",
                student: student
            )
            context.insert(transaction)
        }

        try context.save()
        AnalyticsService.logLesson(
            billingMode: student.billingMode,
            lessonType: lessonType,
            paidImmediately: markPaidImmediately
        )
        AppReviewPrompt.askIfEligible(lessonCount: recordedLessonCount(context: context))
        return record
    }

    static func updateLesson(
        _ record: LessonRecord,
        date: Date,
        durationHours: Double,
        subject: String,
        unitPriceCents: Int,
        lessonType: LessonType,
        note: String,
        context: ModelContext
    ) throws {
        guard record.isEditable else {
            throw BillingError.lessonNotEditable
        }

        record.date = date
        record.durationHours = durationHours
        record.subject = subject
        record.unitPriceCents = unitPriceCents
        record.type = lessonType
        record.amountCents = calculateAmountCents(
            unitPriceCents: unitPriceCents,
            durationHours: durationHours,
            lessonType: lessonType
        )
        record.note = note
        record.updatedAt = .now
        record.student?.updatedAt = .now
        try context.save()
    }

    static func voidLesson(
        _ record: LessonRecord,
        reason: String,
        context: ModelContext
    ) throws {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty else {
            throw BillingError.voidReasonRequired
        }
        guard record.billingStatus != .void else {
            throw BillingError.lessonAlreadyVoid
        }
        guard record.isVoidable else {
            throw record.bill != nil
                ? BillingError.lessonAlreadyBilled
                : BillingError.lessonNotVoidable
        }
        guard record.bill == nil else {
            throw BillingError.lessonAlreadyBilled
        }

        if record.billingStatus == .deducted, let student = record.student {
            student.packageRemainingHours += 1
            let transaction = PackageTransaction(
                type: .adjust,
                hours: 1,
                note: "作废课时返还：\(trimmedReason)",
                student: student
            )
            context.insert(transaction)
        }

        record.billingStatus = .void
        record.voidReason = trimmedReason
        record.updatedAt = .now
        record.student?.updatedAt = .now
        try context.save()
    }

    static func markLessonPaid(
        _ record: LessonRecord,
        paymentMethod: PaymentMethod,
        paidAt: Date,
        context: ModelContext
    ) throws {
        guard record.billingStatus == .pending else {
            throw BillingError.invalidStatusTransition
        }
        record.billingStatus = .paid
        record.paymentMethod = paymentMethod
        record.paidAt = paidAt
        record.updatedAt = .now
        record.student?.updatedAt = .now
        try context.save()
        AnalyticsService.markPaid(
            source: "lesson",
            billingMode: record.student?.billingMode,
            paymentMethod: paymentMethod
        )
    }

    @discardableResult
    static func purchasePackage(
        student: Student,
        hours: Int,
        amountCents: Int?,
        note: String,
        context: ModelContext
    ) throws -> PackageTransaction {
        guard student.billingMode == .prepaid else {
            throw BillingError.notPrepaidStudent
        }

        student.packageTotalHours += hours
        student.packageRemainingHours += hours
        student.updatedAt = .now

        let transaction = PackageTransaction(
            type: .purchase,
            hours: hours,
            amountCents: amountCents,
            note: note.isEmpty ? "购课 \(hours) 节" : note,
            student: student
        )
        context.insert(transaction)
        try context.save()
        AnalyticsService.packagePurchase(
            hours: hours,
            source: "renewal",
            hasAmount: amountCents != nil
        )
        return transaction
    }

    @discardableResult
    static func insertOpeningPackage(
        student: Student,
        hours: Int,
        context: ModelContext
    ) -> PackageTransaction? {
        guard student.billingMode == .prepaid, hours > 0 else { return nil }
        let transaction = PackageTransaction(
            type: .purchase,
            hours: hours,
            note: "建档购课 \(hours) 节",
            student: student
        )
        context.insert(transaction)
        return transaction
    }

    @discardableResult
    static func createBill(
        student: Student,
        lessons: [LessonRecord],
        periodStart: Date,
        periodEnd: Date,
        note: String,
        context: ModelContext
    ) throws -> Bill {
        let pendingLessons = lessons.filter {
            $0.student?.id == student.id && $0.billingStatus == .pending
        }
        guard !pendingLessons.isEmpty else {
            throw BillingError.noPendingLessons
        }

        let total = pendingLessons.reduce(0) { $0 + $1.amountCents }
        let bill = Bill(
            periodStart: periodStart,
            periodEnd: periodEnd,
            totalAmountCents: total,
            status: .draft,
            note: note,
            student: student,
            lessons: pendingLessons
        )
        context.insert(bill)

        for lesson in pendingLessons {
            lesson.billingStatus = .billed
            lesson.bill = bill
            lesson.updatedAt = .now
        }

        student.updatedAt = .now
        try context.save()
        AnalyticsService.generateBill(
            billingMode: student.billingMode,
            lessonCount: pendingLessons.count
        )
        AppReviewPrompt.askIfEligible(
            lessonCount: recordedLessonCount(context: context),
            justCreatedBill: true
        )
        return bill
    }

    static func markBillSent(_ bill: Bill, context: ModelContext) throws {
        guard bill.status == .draft else { throw BillingError.invalidStatusTransition }
        bill.status = .sent
        bill.updatedAt = .now
        try context.save()
    }

    static func markBillPaid(
        _ bill: Bill,
        paymentMethod: PaymentMethod,
        paidAt: Date,
        context: ModelContext
    ) throws {
        guard bill.status != .paid else { throw BillingError.invalidStatusTransition }

        bill.status = .paid
        bill.paymentMethod = paymentMethod
        bill.paidAt = paidAt
        bill.updatedAt = .now

        for lesson in bill.lessons {
            lesson.billingStatus = .paid
            lesson.updatedAt = .now
        }

        bill.student?.updatedAt = .now
        try context.save()
        AnalyticsService.markPaid(
            source: "bill",
            billingMode: bill.student?.billingMode,
            paymentMethod: paymentMethod
        )
    }

    static func cancelBill(_ bill: Bill, context: ModelContext) throws {
        guard bill.status != .paid else { throw BillingError.billAlreadyPaid }

        for lesson in bill.lessons {
            lesson.billingStatus = .pending
            lesson.bill = nil
            lesson.updatedAt = .now
        }

        bill.student?.updatedAt = .now
        context.delete(bill)
        try context.save()
    }

    static func deleteStudent(_ student: Student, context: ModelContext) throws {
        context.delete(student)
        try context.save()
    }

    private static func recordedLessonCount(context: ModelContext) -> Int {
        (try? context.fetchCount(FetchDescriptor<LessonRecord>())) ?? 0
    }
}

enum BillingError: LocalizedError {
    case insufficientPackageHours
    case lessonNotEditable
    case lessonAlreadyVoid
    case lessonAlreadyBilled
    case lessonNotVoidable
    case voidReasonRequired
    case invalidStatusTransition
    case notPrepaidStudent
    case noPendingLessons
    case billAlreadyPaid

    var errorDescription: String? {
        switch self {
        case .insufficientPackageHours:
            return String(localized: "课包剩余课时不足")
        case .lessonNotEditable:
            return String(localized: "该课时已出账或已收款，无法编辑")
        case .lessonAlreadyVoid:
            return String(localized: "该课时已作废")
        case .lessonAlreadyBilled:
            return String(localized: "该课时已关联账单，请先处理账单")
        case .lessonNotVoidable:
            return String(localized: "已出账或已收款的课时不能直接作废")
        case .voidReasonRequired:
            return String(localized: "请填写作废原因")
        case .invalidStatusTransition:
            return String(localized: "当前状态不允许此操作")
        case .notPrepaidStudent:
            return String(localized: "仅先付课包学生可购课")
        case .noPendingLessons:
            return String(localized: "没有可出账的待结算课时")
        case .billAlreadyPaid:
            return String(localized: "账单已收款，无法撤销")
        }
    }
}
