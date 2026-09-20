import Foundation
import SwiftData

enum DemoLaunch {
    static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static var shouldSeed: Bool {
        arguments.contains("-TLDemoSeed") || arguments.contains("-TLResetDemo")
    }

    static var shouldReset: Bool {
        arguments.contains("-TLResetDemo")
    }

    static var skipLaunch: Bool {
        arguments.contains("-TLSkipLaunch")
    }

    static var skipOnboarding: Bool {
        arguments.contains("-TLSkipOnboarding") || shouldSeed
    }

    static var tab: TLTab? {
        switch value(for: "-TLTab") {
        case "home": .home
        case "students": .students
        case "bills": .bills
        case "stats": .stats
        case "settings": .settings
        default: nil
        }
    }

    static var openLessons: Bool {
        arguments.contains("-TLOpenLessons")
    }

    static var openStudent: String? {
        value(for: "-TLOpenStudent")
    }

    static var isArts: Bool {
        arguments.contains("-TLArts")
    }

    static var isEnglish: Bool {
        if arguments.contains("-TLEnglish") { return true }
        if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let first = languages.first {
            return first.hasPrefix("en")
        }
        return Locale.current.language.languageCode?.identifier == "en"
    }

    private static func value(for flag: String) -> String? {
        if let raw = arguments.first(where: { $0.hasPrefix("\(flag)=") }) {
            return String(raw.dropFirst(flag.count + 1))
        }
        if let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }
        return nil
    }
}

enum DemoSeed {
    static var prepaidName: String {
        if DemoLaunch.isArts {
            return DemoLaunch.isEnglish ? "Mia · Piano" : "小雨妈-钢琴"
        }
        return DemoLaunch.isEnglish ? "Mia · G8 Math" : "小雨妈-初二数学"
    }

    static func populate(container: ModelContainer, reset: Bool) {
        populate(context: ModelContext(container), reset: reset)
    }

    static func populate(context: ModelContext, reset: Bool) {
        AppSettings.isDemoData = true
        let existing = (try? context.fetch(FetchDescriptor<Student>())) ?? []
        if !existing.isEmpty {
            guard reset else { return }
            for student in existing {
                context.delete(student)
            }
            try? context.save()
        }

        let calendar = Calendar.current
        let now = Date.now
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let todayDay = calendar.component(.day, from: now)

        func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = min(max(day, 1), todayDay)
            components.hour = hour
            components.minute = minute
            return calendar.date(from: components) ?? now
        }

        func futureDay(_ offset: Int, _ hour: Int) -> Date {
            let start = calendar.startOfDay(for: now)
            let day = calendar.date(byAdding: .day, value: offset, to: start) ?? now
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        }

        let en = DemoLaunch.isEnglish
        let arts = DemoLaunch.isArts

        func include(_ day: Int) -> Bool {
            day >= 1 && day <= todayDay
        }

        let xiaoyu = Student(
            name: prepaidName,
            grade: arts ? .primary : .junior,
            subjects: [arts ? (en ? "Piano" : "钢琴") : (en ? "Math" : "数学")],
            billingMode: .prepaid,
            defaultUnitPriceCents: 20_000,
            packageTotalHours: 10,
            packageRemainingHours: 3,
            note: en ? "Prepaid 10 sessions, 3 left — time to renew" : "先付 10 节，剩 3 节该提醒续费",
            nextLessonAt: futureDay(1, 18),
            defaultDurationHours: 2
        )
        let haoran = Student(
            name: arts ? (en ? "Ethan · Dance" : "浩然爸-中国舞") : (en ? "Ethan · Physics" : "浩然爸-高一物理"),
            grade: arts ? .primary : .senior,
            subjects: [arts ? (en ? "Dance" : "中国舞") : (en ? "Physics" : "物理")],
            billingMode: .postpaid,
            defaultUnitPriceCents: 26_000,
            settlementCycle: .monthly,
            note: en ? "Monthly settle via WeChat" : "月结，微信对账",
            nextLessonAt: futureDay(2, 19),
            defaultDurationHours: 2
        )
        let siqi = Student(
            name: arts ? (en ? "Sienna · Chess" : "思齐-少儿象棋") : (en ? "Sienna · English" : "思齐-小学英语"),
            grade: .primary,
            subjects: [arts ? (en ? "Chess" : "象棋") : (en ? "English" : "英语")],
            billingMode: .perSession,
            defaultUnitPriceCents: 12_000,
            settlementCycle: .weekly,
            note: en ? "Pay after each lesson" : "下课微信现结",
            defaultDurationHours: 1.5
        )
        let linlin = Student(
            name: arts ? (en ? "Lynn · Guzheng" : "林林妈-古筝") : (en ? "Lynn · Chemistry" : "林林妈-初三化学"),
            grade: arts ? .primary : .junior,
            subjects: [arts ? (en ? "Guzheng" : "古筝") : (en ? "Chemistry" : "化学")],
            billingMode: .postpaid,
            defaultUnitPriceCents: 22_000,
            settlementCycle: .monthly,
            defaultDurationHours: 2
        )
        let anan = Student(
            name: arts ? (en ? "Anna · Hip-hop" : "安安-街舞") : (en ? "Anna · G11 Math" : "安安-高二数学"),
            grade: arts ? .junior : .senior,
            subjects: [arts ? (en ? "Hip-hop" : "街舞") : (en ? "Math" : "数学")],
            billingMode: .prepaid,
            defaultUnitPriceCents: 28_000,
            packageTotalHours: 20,
            packageRemainingHours: 14,
            note: arts
                ? (en ? "Grade-exam surcharge saved on that lesson" : "考级加价已写进当次单价")
                : (en ? "Exam surcharge saved on that lesson" : "竞赛加价已写进当次单价"),
            nextLessonAt: futureDay(3, 19),
            defaultDurationHours: 2
        )

        [xiaoyu, haoran, siqi, linlin, anan].forEach { context.insert($0) }

        context.insert(PackageTransaction(
            type: .purchase,
            hours: 10,
            amountCents: 400_000,
            date: at(1, 10),
            note: en ? "Bought 10 sessions" : "购入 10 节课包",
            student: xiaoyu
        ))
        context.insert(PackageTransaction(
            type: .purchase,
            hours: 20,
            amountCents: 560_000,
            date: at(1, 11),
            note: en ? "Bought 20 sessions" : "购入 20 节课包",
            student: anan
        ))

        @discardableResult
        func addLesson(
            _ student: Student,
            day: Int,
            hour: Int,
            minute: Int = 0,
            duration: Double? = nil,
            type: LessonType = .normal,
            status: LessonBillingStatus,
            note: String = "",
            voidReason: String? = nil,
            payment: PaymentMethod? = nil,
            unitPrice: Int? = nil
        ) -> LessonRecord? {
            guard include(day) else { return nil }
            let date = at(day, hour, minute)
            let price = unitPrice ?? student.defaultUnitPriceCents
            let hours = duration ?? student.defaultDurationHours
            let amount = BillingService.calculateAmountCents(
                unitPriceCents: price,
                durationHours: hours,
                lessonType: type
            )
            let record = LessonRecord(
                date: date,
                durationHours: hours,
                subject: student.primarySubject,
                unitPriceCents: price,
                amountCents: amount,
                type: type,
                billingStatus: status,
                note: note,
                voidReason: voidReason,
                paymentMethod: payment,
                paidAt: status == .paid ? date : nil,
                student: student
            )
            context.insert(record)

            if status == .deducted {
                context.insert(PackageTransaction(
                    type: .deduct,
                    hours: 1,
                    date: date,
                    note: en ? "Lesson deducted" : "上课扣课",
                    student: student
                ))
            }
            if status == .void, let voidReason {
                context.insert(PackageTransaction(
                    type: .adjust,
                    hours: 1,
                    date: date,
                    note: en ? "Void refund: \(voidReason)" : "作废课时返还：\(voidReason)",
                    student: student
                ))
            }
            return record
        }

        // 小雨：8 节已扣 + 1 节请假作废返还 → 剩余 3
        for (day, hour) in [(3, 18), (6, 18), (10, 18), (13, 19), (17, 18), (20, 18), (24, 18), (27, 18)] {
            addLesson(xiaoyu, day: day, hour: hour, status: .deducted)
        }
        addLesson(
            xiaoyu,
            day: 8,
            hour: 18,
            status: .void,
            note: en ? "Did not attend" : "当天未上",
            voidReason: en ? "Student absence" : "学生请假"
        )

        // 安安：6 节已扣，剩余 14
        for (day, hour) in [(4, 19), (11, 19), (15, 19), (18, 19), (22, 19), (25, 19)] {
            addLesson(anan, day: day, hour: hour, status: .deducted)
        }

        // 浩然：上半月已出账已发送，近几节待结算（账单页主视觉）
        let haoranBilled = [
            addLesson(haoran, day: 2, hour: 19, status: .billed),
            addLesson(haoran, day: 9, hour: 19, status: .billed),
            addLesson(haoran, day: 16, hour: 19, status: .billed, note: arts ? (en ? "Recital surcharge" : "演出加价") : (en ? "Exam surcharge" : "临考加价"), unitPrice: 30_000)
        ].compactMap { $0 }
        addLesson(haoran, day: max(todayDay - 4, 1), hour: 19, status: .pending)
        addLesson(haoran, day: max(todayDay - 2, 1), hour: 19, status: .pending)
        addLesson(haoran, day: todayDay, hour: 19, minute: 30, status: .pending)

        if !haoranBilled.isEmpty {
            let start = at(1, 0)
            let end = at(min(16, todayDay), 23, 59)
            let total = haoranBilled.reduce(0) { $0 + $1.amountCents }
            let bill = Bill(
                periodStart: start,
                periodEnd: end,
                totalAmountCents: total,
                status: .sent,
                note: arts ? (en ? "First-half dance" : "8 月上半月中国舞") : (en ? "First-half physics" : "8 月上半月物理"),
                student: haoran,
                lessons: haoranBilled
            )
            context.insert(bill)
            for lesson in haoranBilled {
                lesson.bill = bill
            }
        }

        // 林林：本月已收款账单
        let linlinPaid = [
            addLesson(linlin, day: 5, hour: 18, status: .paid, payment: .wechat),
            addLesson(linlin, day: 12, hour: 18, status: .paid, payment: .wechat),
            addLesson(linlin, day: 19, hour: 18, status: .paid, payment: .wechat),
            addLesson(linlin, day: 26, hour: 18, status: .paid, payment: .wechat)
        ].compactMap { $0 }
        if !linlinPaid.isEmpty {
            let start = at(1, 0)
            let end = at(min(26, todayDay), 23, 59)
            let total = linlinPaid.reduce(0) { $0 + $1.amountCents }
            let paidAt = linlinPaid.last?.date ?? now
            let bill = Bill(
                periodStart: start,
                periodEnd: end,
                totalAmountCents: total,
                status: .paid,
                paidAt: paidAt,
                paymentMethod: .wechat,
                note: arts ? (en ? "August guzheng pay" : "本月古筝课酬") : (en ? "August chemistry pay" : "本月化学课酬"),
                student: linlin,
                lessons: linlinPaid
            )
            context.insert(bill)
            for lesson in linlinPaid {
                lesson.bill = bill
            }
        }

        // 思齐：按次现结，含今天一节
        addLesson(siqi, day: 7, hour: 16, type: .trial, status: .paid, note: en ? "Trial half-rate" : "试讲半价", payment: .wechat)
        addLesson(siqi, day: 14, hour: 16, status: .paid, payment: .wechat)
        addLesson(siqi, day: 21, hour: 16, status: .paid, payment: .alipay)
        addLesson(siqi, day: 23, hour: 16, type: .makeup, status: .paid, note: en ? "Makeup for last week" : "补上周请假", payment: .wechat)
        addLesson(siqi, day: todayDay, hour: 16, status: .paid, payment: .wechat)

        try? context.save()
    }
}
