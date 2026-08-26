import Foundation

enum BillsViewMode: String, CaseIterable, Identifiable {
    case pendingToBill
    case issued

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pendingToBill: String(localized: "待出账")
        case .issued: String(localized: "已出账单")
        }
    }

    var subtitle: String {
        switch self {
        case .pendingToBill: String(localized: "课后课时，尚未生成账单")
        case .issued: String(localized: "已按学生汇总，可分享对账")
        }
    }
}

enum BillsTimePreset: String, CaseIterable, Identifiable {
    case month
    case all
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: String(localized: "本月")
        case .all: String(localized: "全部时间")
        case .custom: String(localized: "自定义")
        }
    }
}

struct BillsDateRange {
    var start: Date?
    var end: Date?

    var isUnbounded: Bool { start == nil && end == nil }

    func contains(_ date: Date) -> Bool {
        if let start, date < start { return false }
        if let end, date > end { return false }
        return true
    }

    func overlaps(periodStart: Date, periodEnd: Date) -> Bool {
        if isUnbounded { return true }
        let rangeStart = start ?? .distantPast
        let rangeEnd = end ?? .distantFuture
        return periodStart <= rangeEnd && periodEnd >= rangeStart
    }

    static func resolve(
        preset: BillsTimePreset,
        customStart: Date,
        customEnd: Date,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> BillsDateRange {
        switch preset {
        case .month:
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                return BillsDateRange(start: nil, end: nil)
            }
            return BillsDateRange(start: monthStart, end: endOfDay(now, calendar: calendar))
        case .all:
            return BillsDateRange(start: nil, end: nil)
        case .custom:
            let orderedStart = calendar.startOfDay(for: min(customStart, customEnd))
            let orderedEnd = endOfDay(max(customStart, customEnd), calendar: calendar)
            return BillsDateRange(start: orderedStart, end: orderedEnd)
        }
    }

    static func displayTitle(
        preset: BillsTimePreset,
        customStart: Date,
        customEnd: Date
    ) -> String {
        switch preset {
        case .month:
            return String(localized: "本月")
        case .all:
            return String(localized: "全部时间")
        case .custom:
            let start = min(customStart, customEnd)
            let end = max(customStart, customEnd)
            return "\(TLDateFormat.mediumDate(start)) – \(TLDateFormat.mediumDate(end))"
        }
    }

    static func endOfDay(_ date: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
    }
}

enum BillsStatusFilter: String, CaseIterable, Identifiable {
    case all
    case unpaid
    case draft
    case sent
    case paid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: String(localized: "全部状态")
        case .unpaid: String(localized: "待收款")
        case .draft: String(localized: "待发送")
        case .sent: String(localized: "已发送")
        case .paid: String(localized: "已收款")
        }
    }

    func matches(_ status: BillStatus) -> Bool {
        switch self {
        case .all: true
        case .unpaid: status != .paid
        case .draft: status == .draft
        case .sent: status == .sent
        case .paid: status == .paid
        }
    }
}

enum BillsFilterCategory: String, Identifiable {
    case time
    case status
    case student

    var id: String { rawValue }

    var title: String {
        switch self {
        case .time: String(localized: "时间范围")
        case .status: String(localized: "账单状态")
        case .student: String(localized: "学生")
        }
    }
}
