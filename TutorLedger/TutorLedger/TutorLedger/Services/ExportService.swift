import Foundation
import SwiftData

enum ExportService {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    static func makeCSV(context: ModelContext) throws -> String {
        let students = try context.fetch(FetchDescriptor<Student>(sortBy: [SortDescriptor(\.name)]))
        let lessons = try context.fetch(FetchDescriptor<LessonRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        let bills = try context.fetch(FetchDescriptor<Bill>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        let packageTransactions = try context.fetch(
            FetchDescriptor<PackageTransaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        )

        var lines: [String] = []

        lines.append(String(localized: "=== 学生 ==="))
        lines.append(String(localized: "姓名,年级,科目,计费模式,默认单价,剩余课时,状态,备注"))
        for student in students {
            lines.append([
                csvEscape(student.name),
                csvEscape(student.grade.title),
                csvEscape(student.subjectsRaw),
                csvEscape(student.billingMode.title),
                MoneyFormat.display(cents: student.defaultUnitPriceCents),
                String(student.packageRemainingHours),
                csvEscape(student.status.title),
                csvEscape(student.note)
            ].joined(separator: ","))
        }

        lines.append("")
        lines.append(String(localized: "=== 课时记录 ==="))
        lines.append(String(localized: "日期,学生,科目,时长,单价,金额,类型,状态,收款方式,收款日期,备注"))
        for lesson in lessons {
            lines.append(lessonRow(lesson, includeStudent: true))
        }

        lines.append("")
        lines.append(String(localized: "=== 账单 ==="))
        lines.append(String(localized: "账期开始,账期结束,学生,合计,状态,收款方式,收款日期,备注"))
        for bill in bills {
            lines.append(billSummaryRow(bill))
        }

        lines.append("")
        lines.append(String(localized: "=== 课包流水 ==="))
        lines.append(String(localized: "日期,学生,类型,节数,实收金额,备注"))
        for transaction in packageTransactions {
            lines.append([
                csvEscape(isoFormatter.string(from: transaction.date)),
                csvEscape(transaction.student?.name ?? ""),
                csvEscape(transaction.type.title),
                String(transaction.hours),
                transaction.amountCents.map { MoneyFormat.display(cents: $0) } ?? "",
                csvEscape(transaction.note)
            ].joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    static func makeBillShareText(bill: Bill) -> String {
        let studentName = bill.student?.name ?? String(localized: "学生")
        let lessons = bill.lessons.sorted { $0.date < $1.date }
        var lines: [String] = [
            String(localized: "【课酬记】\(studentName)"),
            String(localized: "账期：\(bill.periodTitle)"),
            String(localized: "共 \(lessons.count) 节 · 合计 \(MoneyFormat.display(cents: bill.totalAmountCents))")
        ]
        if !bill.note.isEmpty {
            lines.append(String(format: String(localized: "备注：%@"), bill.note))
        }
        lines.append("")
        lines.append(String(localized: "明细："))
        for lesson in lessons {
            lines.append(
                "\(TLDateFormat.monthDay(lesson.date))  \(lesson.subject)  \(MoneyFormat.display(hours: lesson.durationHours))  \(MoneyFormat.display(cents: lesson.amountCents))"
            )
        }
        lines.append("")
        lines.append(String(localized: "请核对后转账，谢谢。"))
        return lines.joined(separator: "\n")
    }

    static func makeBillCSV(bill: Bill) -> String {
        var lines: [String] = []
        let studentName = bill.student?.name ?? String(localized: "学生")

        lines.append(String(localized: "=== 账单摘要 ==="))
        lines.append(String(localized: "学生,账期开始,账期结束,合计,状态,收款方式,收款日期,备注"))
        lines.append(billSummaryRow(bill))

        lines.append("")
        lines.append(String(localized: "=== 课时明细 ==="))
        lines.append(String(localized: "日期,科目,时长,单价,金额,备注"))
        for lesson in bill.lessons.sorted(by: { $0.date > $1.date }) {
            lines.append(lessonRow(lesson, includeStudent: false))
        }

        lines.append("")
        lines.append(String(format: String(localized: "导出说明,课酬记 · %@ · %@"), studentName, bill.periodTitle))

        return lines.joined(separator: "\n")
    }

    static func makePendingLessonsCSV(student: Student, lessons: [LessonRecord]) -> String {
        makeFilteredPendingCSV(
            scope: ExportScope(
                type: String(localized: "待出账"),
                timeRange: String(localized: "单学生"),
                student: student.name,
                status: nil
            ),
            groups: [(student, lessons)]
        )
    }

    static func makeFilteredPendingCSV(
        scope: ExportScope,
        groups: [(Student, [LessonRecord])]
    ) -> String {
        let sortedGroups = groups.sorted { $0.0.name.localizedCompare($1.0.name) == .orderedAscending }
        let totalLessons = sortedGroups.reduce(0) { $0 + $1.1.count }
        let totalCents = sortedGroups.reduce(0) { partial, group in
            partial + group.1.reduce(0) { $0 + $1.amountCents }
        }

        var lines = scopeHeaderLines(scope)

        lines.append("")
        lines.append(String(localized: "=== 待出账汇总 ==="))
        lines.append(String(localized: "学生数,课时数,合计"))
        lines.append([
            String(sortedGroups.count),
            String(totalLessons),
            MoneyFormat.display(cents: totalCents)
        ].joined(separator: ","))

        lines.append("")
        lines.append(String(localized: "=== 各学生汇总 ==="))
        lines.append(String(localized: "学生,课时数,合计"))
        for (student, lessons) in sortedGroups {
            let total = lessons.reduce(0) { $0 + $1.amountCents }
            lines.append([
                csvEscape(student.name),
                String(lessons.count),
                MoneyFormat.display(cents: total)
            ].joined(separator: ","))
        }

        lines.append("")
        lines.append(String(localized: "=== 课时明细 ==="))
        lines.append(String(localized: "学生,日期,科目,时长,单价,金额,备注"))
        for (student, lessons) in sortedGroups {
            for lesson in lessons.sorted(by: { $0.date > $1.date }) {
                lines.append([
                    csvEscape(student.name),
                    csvEscape(isoFormatter.string(from: lesson.date)),
                    csvEscape(lesson.subject),
                    String(format: "%.1f", lesson.durationHours),
                    MoneyFormat.display(cents: lesson.unitPriceCents),
                    MoneyFormat.display(cents: lesson.amountCents),
                    csvEscape(lesson.note)
                ].joined(separator: ","))
            }
        }

        lines.append("")
        lines.append(String(format: String(localized: "导出说明,课酬记 · %@ · 待出账"), scope.exportLabel))

        return lines.joined(separator: "\n")
    }

    static func makeFilteredBillsCSV(
        scope: ExportScope,
        groups: [(Student, [Bill])]
    ) -> String {
        let sortedGroups = groups.sorted { $0.0.name.localizedCompare($1.0.name) == .orderedAscending }
        let allBills = sortedGroups.flatMap(\.1)
        let totalCents = allBills.reduce(0) { $0 + $1.totalAmountCents }

        var lines = scopeHeaderLines(scope)

        lines.append("")
        lines.append(String(localized: "=== 账单汇总 ==="))
        lines.append(String(localized: "学生数,账单数,合计"))
        lines.append([
            String(sortedGroups.count),
            String(allBills.count),
            MoneyFormat.display(cents: totalCents)
        ].joined(separator: ","))

        lines.append("")
        lines.append(String(localized: "=== 各学生汇总 ==="))
        lines.append(String(localized: "学生,账单数,合计"))
        for (student, bills) in sortedGroups {
            let total = bills.reduce(0) { $0 + $1.totalAmountCents }
            lines.append([
                csvEscape(student.name),
                String(bills.count),
                MoneyFormat.display(cents: total)
            ].joined(separator: ","))
        }

        lines.append("")
        lines.append(String(localized: "=== 账单列表 ==="))
        lines.append(String(localized: "学生,账期开始,账期结束,合计,状态,课时数,收款方式,收款日期,备注"))
        for (student, bills) in sortedGroups {
            for bill in bills.sorted(by: { $0.createdAt > $1.createdAt }) {
                lines.append([
                    csvEscape(student.name),
                    csvEscape(isoFormatter.string(from: bill.periodStart)),
                    csvEscape(isoFormatter.string(from: bill.periodEnd)),
                    MoneyFormat.display(cents: bill.totalAmountCents),
                    csvEscape(bill.status.title),
                    String(bill.lessons.count),
                    csvEscape(bill.paymentMethod?.title ?? ""),
                    bill.paidAt.map { csvEscape(isoFormatter.string(from: $0)) } ?? "",
                    csvEscape(bill.note)
                ].joined(separator: ","))
            }
        }

        lines.append("")
        lines.append(String(localized: "=== 各账单课时明细 ==="))
        lines.append(String(localized: "学生,账期,日期,科目,时长,单价,金额,备注"))
        for (student, bills) in sortedGroups {
            for bill in bills.sorted(by: { $0.createdAt > $1.createdAt }) {
                let period = bill.periodTitle
                for lesson in bill.lessons.sorted(by: { $0.date > $1.date }) {
                    lines.append([
                        csvEscape(student.name),
                        csvEscape(period),
                        csvEscape(isoFormatter.string(from: lesson.date)),
                        csvEscape(lesson.subject),
                        String(format: "%.1f", lesson.durationHours),
                        MoneyFormat.display(cents: lesson.unitPriceCents),
                        MoneyFormat.display(cents: lesson.amountCents),
                        csvEscape(lesson.note)
                    ].joined(separator: ","))
                }
            }
        }

        lines.append("")
        lines.append(String(format: String(localized: "导出说明,课酬记 · %@ · 已出账单"), scope.exportLabel))

        return lines.joined(separator: "\n")
    }

    static func makeStudentBillsCSV(student: Student, bills: [Bill]) -> String {
        makeFilteredBillsCSV(
            scope: ExportScope(
                type: String(localized: "已出账单"),
                timeRange: String(localized: "单学生"),
                student: student.name,
                status: nil
            ),
            groups: [(student, bills)]
        )
    }

    struct ExportScope {
        let type: String
        let timeRange: String
        let student: String
        let status: String?

        var exportLabel: String {
            [type, timeRange, student].joined(separator: " · ")
        }
    }

    private static func scopeHeaderLines(_ scope: ExportScope) -> [String] {
        var lines = [String(localized: "=== 导出范围 ==="), String(localized: "字段,值")]
        lines.append([String(localized: "类型"), csvEscape(scope.type)].joined(separator: ","))
        lines.append([String(localized: "时间范围"), csvEscape(scope.timeRange)].joined(separator: ","))
        lines.append([String(localized: "学生"), csvEscape(scope.student)].joined(separator: ","))
        if let status = scope.status {
            lines.append([String(localized: "账单状态"), csvEscape(status)].joined(separator: ","))
        }
        return lines
    }

    private static func billSummaryRow(_ bill: Bill) -> String {
        [
            csvEscape(bill.student?.name ?? ""),
            csvEscape(isoFormatter.string(from: bill.periodStart)),
            csvEscape(isoFormatter.string(from: bill.periodEnd)),
            MoneyFormat.display(cents: bill.totalAmountCents),
            csvEscape(bill.status.title),
            csvEscape(bill.paymentMethod?.title ?? ""),
            bill.paidAt.map { csvEscape(isoFormatter.string(from: $0)) } ?? "",
            csvEscape(bill.note)
        ].joined(separator: ",")
    }

    private static func lessonRow(_ lesson: LessonRecord, includeStudent: Bool) -> String {
        var fields = [csvEscape(isoFormatter.string(from: lesson.date))]
        if includeStudent {
            fields.append(csvEscape(lesson.student?.name ?? ""))
        }
        fields.append(contentsOf: [
            csvEscape(lesson.subject),
            String(format: "%.1f", lesson.durationHours),
            MoneyFormat.display(cents: lesson.unitPriceCents),
            MoneyFormat.display(cents: lesson.amountCents)
        ])
        if includeStudent {
            fields.append(contentsOf: [
                csvEscape(lesson.type.title),
                csvEscape(lesson.billingStatus.title),
                csvEscape(lesson.paymentMethod?.title ?? ""),
                lesson.paidAt.map { csvEscape(isoFormatter.string(from: $0)) } ?? "",
                csvEscape(lesson.note)
            ])
        } else {
            fields.append(csvEscape(lesson.note))
        }
        return fields.joined(separator: ",")
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
