import Foundation

enum MoneyFormat {
    static func centsToYuan(_ cents: Int) -> Decimal {
        Decimal(cents) / 100
    }

    static func yuanToCents(_ yuan: Decimal) -> Int {
        let scaled = yuan * 100
        return NSDecimalNumber(decimal: scaled).intValue
    }

    static func display(cents: Int, currencySymbol: String? = nil) -> String {
        let symbol = currencySymbol ?? AppSettings.currencySymbol
        let amount = Double(cents) / 100.0
        return String(format: "%@%.2f", symbol, amount)
    }

    static func display(hours: Double) -> String {
        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: String(localized: "%.0f 小时"), hours)
        }
        return String(format: String(localized: "%.1f 小时"), hours)
    }
}

enum TLDateFormat {
    private static func formatter(
        dateStyle: DateFormatter.Style = .none,
        timeStyle: DateFormatter.Style = .none,
        template: String? = nil
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        if let template {
            formatter.setLocalizedDateFormatFromTemplate(template)
        } else {
            formatter.dateStyle = dateStyle
            formatter.timeStyle = timeStyle
        }
        return formatter
    }

    /// Localized medium date (e.g. yyyy年M月d日)
    static func mediumDate(_ date: Date) -> String {
        formatter(dateStyle: .medium).string(from: date)
    }

    /// Localized medium date + short time
    static func mediumDateTime(_ date: Date) -> String {
        formatter(dateStyle: .medium, timeStyle: .short).string(from: date)
    }

    /// Localized year + month
    static func yearMonth(_ date: Date) -> String {
        formatter(template: "yMMM").string(from: date)
    }

    /// Localized month + day
    static func monthDay(_ date: Date) -> String {
        formatter(template: "MMMd").string(from: date)
    }

    /// Localized month + day + time
    static func monthDayTime(_ date: Date) -> String {
        formatter(template: "MMMdjm").string(from: date)
    }

    /// Localized month + day + weekday
    static func monthDayWeekday(_ date: Date) -> String {
        formatter(template: "MMMEd").string(from: date)
    }

    /// Localized short time
    static func time(_ date: Date) -> String {
        formatter(dateStyle: .none, timeStyle: .short).string(from: date)
    }
}
