import Foundation
import SwiftData

@Model
final class Student {
    @Attribute(.unique) var id: UUID
    var name: String
    var gradeRaw: String
    var subjectsRaw: String
    var billingModeRaw: String
    var defaultUnitPriceCents: Int
    var groupUnitPriceCents: Int?
    var packageTotalHours: Int
    var packageRemainingHours: Int
    var settlementCycleRaw: String
    var statusRaw: String
    var note: String
    var nextLessonAt: Date?
    var defaultDurationHours: Double
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \LessonRecord.student)
    var lessons: [LessonRecord]

    @Relationship(deleteRule: .cascade, inverse: \Bill.student)
    var bills: [Bill]

    @Relationship(deleteRule: .cascade, inverse: \PackageTransaction.student)
    var packageTransactions: [PackageTransaction]

    init(
        id: UUID = UUID(),
        name: String,
        grade: GradeLevel = .other,
        subjects: [String] = [],
        billingMode: BillingMode,
        defaultUnitPriceCents: Int = 0,
        groupUnitPriceCents: Int? = nil,
        packageTotalHours: Int = 0,
        packageRemainingHours: Int = 0,
        settlementCycle: SettlementCycle = .monthly,
        status: StudentStatus = .active,
        note: String = "",
        nextLessonAt: Date? = nil,
        defaultDurationHours: Double = 2.0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.gradeRaw = grade.rawValue
        self.subjectsRaw = subjects.joined(separator: "、")
        self.billingModeRaw = billingMode.rawValue
        self.defaultUnitPriceCents = defaultUnitPriceCents
        self.groupUnitPriceCents = groupUnitPriceCents
        self.packageTotalHours = packageTotalHours
        self.packageRemainingHours = packageRemainingHours
        self.settlementCycleRaw = settlementCycle.rawValue
        self.statusRaw = status.rawValue
        self.note = note
        self.nextLessonAt = nextLessonAt
        self.defaultDurationHours = defaultDurationHours
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lessons = []
        self.bills = []
        self.packageTransactions = []
    }

    var grade: GradeLevel {
        get { GradeLevel(rawValue: gradeRaw) ?? .other }
        set { gradeRaw = newValue.rawValue }
    }

    var billingMode: BillingMode {
        get { BillingMode(rawValue: billingModeRaw) ?? .postpaid }
        set { billingModeRaw = newValue.rawValue }
    }

    var settlementCycle: SettlementCycle {
        get { SettlementCycle(rawValue: settlementCycleRaw) ?? .monthly }
        set { settlementCycleRaw = newValue.rawValue }
    }

    var status: StudentStatus {
        get { StudentStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var subjects: [String] {
        subjectsRaw
            .split { $0 == "、" || $0 == "," || $0 == "，" }
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var primarySubject: String {
        subjects.first ?? String(localized: "未设置")
    }

    var hasSubjects: Bool { !subjects.isEmpty }

    var isLowPackage: Bool {
        billingMode == .prepaid && status == .active && packageRemainingHours <= 3
    }

    var pendingAmountCents: Int {
        lessons
            .filter { $0.billingStatus == .pending }
            .reduce(0) { $0 + $1.amountCents }
    }
}
