import Foundation
import SwiftData

struct DashboardStats {
    var todayLessons: Int = 0
    var weekLessons: Int = 0
    var monthReceivedCents: Int = 0
    var monthPendingCents: Int = 0
    var lowPackageStudents: [Student] = []
}

struct DayLessonSummary {
    var lessons: [LessonRecord] = []
    var lessonCount: Int = 0
    var totalHours: Double = 0
    var receivedCents: Int = 0
}

enum StatsService {
    static func dashboardStats(context: ModelContext) -> DashboardStats {
        let calendar = Calendar.current
        let now = Date.now
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? startOfDay
        let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? startOfWeek
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? startOfDay
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? startOfMonth

        guard let lessons = try? context.fetch(FetchDescriptor<LessonRecord>()),
              let students = try? context.fetch(FetchDescriptor<Student>()) else {
            return DashboardStats()
        }

        let activeLessons = lessons.filter { $0.billingStatus != .void }

        var stats = DashboardStats()
        stats.todayLessons = activeLessons.filter { $0.date >= startOfDay && $0.date < endOfDay }.count
        stats.weekLessons = activeLessons.filter { $0.date >= startOfWeek && $0.date < endOfWeek }.count

        stats.monthReceivedCents = activeLessons
            .filter { $0.date >= startOfMonth && $0.date < endOfMonth && $0.billingStatus == .paid }
            .reduce(0) { $0 + $1.amountCents }

        stats.monthPendingCents = activeLessons
            .filter { $0.date >= startOfMonth && $0.date < endOfMonth && ($0.billingStatus == .pending || $0.billingStatus == .billed) }
            .reduce(0) { $0 + $1.amountCents }

        stats.lowPackageStudents = students.filter(\.isLowPackage)
        return stats
    }

    static func monthBounds(for month: Date) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else {
            return nil
        }
        return (start, end)
    }

    static func monthReceivedByStudent(context: ModelContext, month: Date) -> [(Student, Int)] {
        guard let (start, end) = monthBounds(for: month),
              let lessons = try? context.fetch(FetchDescriptor<LessonRecord>()) else {
            return []
        }

        var totals: [UUID: Int] = [:]
        for lesson in lessons where lesson.date >= start && lesson.date < end && lesson.billingStatus == .paid {
            guard let id = lesson.student?.id else { continue }
            totals[id, default: 0] += lesson.amountCents
        }

        guard let students = try? context.fetch(FetchDescriptor<Student>()) else { return [] }
        return students
            .compactMap { student -> (Student, Int)? in
                guard let amount = totals[student.id], amount > 0 else { return nil }
                return (student, amount)
            }
            .sorted { $0.1 > $1.1 }
    }

    static func monthLessonCount(context: ModelContext, month: Date) -> Int {
        guard let (start, end) = monthBounds(for: month),
              let lessons = try? context.fetch(FetchDescriptor<LessonRecord>()) else {
            return 0
        }
        return lessons.filter { $0.date >= start && $0.date < end && $0.billingStatus != .void }.count
    }

    static func monthTotalHours(context: ModelContext, month: Date) -> Double {
        guard let (start, end) = monthBounds(for: month),
              let lessons = try? context.fetch(FetchDescriptor<LessonRecord>()) else {
            return 0
        }
        return lessons
            .filter { $0.date >= start && $0.date < end && $0.billingStatus != .void }
            .reduce(0) { $0 + $1.durationHours }
    }

    static func monthLessonsByStudent(context: ModelContext, month: Date) -> [(Student, Int)] {
        guard let (start, end) = monthBounds(for: month),
              let lessons = try? context.fetch(FetchDescriptor<LessonRecord>()),
              let students = try? context.fetch(FetchDescriptor<Student>()) else {
            return []
        }

        var counts: [UUID: Int] = [:]
        for lesson in lessons where lesson.date >= start && lesson.date < end && lesson.billingStatus != .void {
            guard let id = lesson.student?.id else { continue }
            counts[id, default: 0] += 1
        }

        return students
            .compactMap { student -> (Student, Int)? in
                guard let count = counts[student.id], count > 0 else { return nil }
                return (student, count)
            }
            .sorted { $0.1 > $1.1 }
    }

    static func lessonDaysInMonth(context: ModelContext, month: Date) -> Set<Date> {
        guard let (start, end) = monthBounds(for: month),
              let lessons = try? context.fetch(FetchDescriptor<LessonRecord>()) else {
            return []
        }

        let calendar = Calendar.current
        var days = Set<Date>()
        for lesson in lessons where lesson.date >= start && lesson.date < end && lesson.billingStatus != .void {
            days.insert(calendar.startOfDay(for: lesson.date))
        }
        return days
    }

    static func dayLessonSummary(context: ModelContext, day: Date) -> DayLessonSummary {
        guard let lessons = try? context.fetch(FetchDescriptor<LessonRecord>()) else {
            return DayLessonSummary()
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return DayLessonSummary()
        }

        let dayLessons = lessons
            .filter { $0.date >= start && $0.date < end && $0.billingStatus != .void }
            .sorted { $0.date < $1.date }

        return DayLessonSummary(
            lessons: dayLessons,
            lessonCount: dayLessons.count,
            totalHours: dayLessons.reduce(0) { $0 + $1.durationHours },
            receivedCents: dayLessons.filter { $0.billingStatus == .paid }.reduce(0) { $0 + $1.amountCents }
        )
    }

    static func upcomingLessons(context: ModelContext, withinDays: Int = 7) -> [(Student, Date)] {
        guard let students = try? context.fetch(FetchDescriptor<Student>()) else { return [] }

        let calendar = Calendar.current
        let now = Date.now
        guard let end = calendar.date(byAdding: .day, value: withinDays, to: now) else { return [] }

        return students
            .filter { $0.status == .active }
            .compactMap { student -> (Student, Date)? in
                guard let next = student.nextLessonAt, next >= now, next <= end else { return nil }
                return (student, next)
            }
            .sorted { $0.1 < $1.1 }
    }
}
