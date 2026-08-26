import Foundation

enum AppSettings {
    private enum Keys {
        static let defaultDurationHours = "defaultDurationHours"
        static let durationPresets = "durationPresets"
        static let currencySymbol = "currencySymbol"
        static let lastExportDate = "lastExportDate"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    static let commonCurrencySymbols = ["¥", "$", "€", "£", "HK$", "NT$", "₩", "S$"]

    static var defaultDurationHours: Double {
        get {
            let value = UserDefaults.standard.double(forKey: Keys.defaultDurationHours)
            return value > 0 ? value : 2.0
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.defaultDurationHours) }
    }

    static var durationPresets: [Double] {
        get {
            guard let raw = UserDefaults.standard.string(forKey: Keys.durationPresets),
                  !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return defaultPresetDurations
            }
            let parsed = raw
                .split(separator: ",")
                .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                .filter { $0 > 0 && $0 <= 24 }
            return parsed.isEmpty ? defaultPresetDurations : parsed.sorted()
        }
        set {
            let text = newValue
                .filter { $0 > 0 && $0 <= 24 }
                .sorted()
                .map { formatDurationValue($0) }
                .joined(separator: ", ")
            UserDefaults.standard.set(text, forKey: Keys.durationPresets)
        }
    }

    static var durationPresetsText: String {
        get { durationPresets.map { formatDurationValue($0) }.joined(separator: ", ") }
        set {
            let parsed = newValue
                .split(separator: ",")
                .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                .filter { $0 > 0 && $0 <= 24 }
            durationPresets = parsed.isEmpty ? defaultPresetDurations : parsed
        }
    }

    static var currencySymbol: String {
        get {
            let value = UserDefaults.standard.string(forKey: Keys.currencySymbol) ?? "¥"
            return value.isEmpty ? "¥" : value
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(trimmed.isEmpty ? "¥" : trimmed, forKey: Keys.currencySymbol)
        }
    }

    static var lastExportDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastExportDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastExportDate) }
    }

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    static var lastExportDisplayText: String {
        guard let date = lastExportDate else { return String(localized: "尚未导出") }
        return TLDateFormat.mediumDateTime(date)
    }

    static var needsBackupReminder: Bool {
        guard let last = lastExportDate else { return true }
        let days = Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0
        return days >= 30
    }

    static var unitPriceLabel: String {
        String(format: String(localized: "%@/小时"), currencySymbol)
    }

    private static let defaultPresetDurations: [Double] = [1.0, 1.5, 2.0, 2.5, 3.0]

    static func formatDurationValue(_ hours: Double) -> String {
        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", hours)
        }
        return String(format: "%.1f", hours)
    }

    static func parseDuration(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed), value > 0, value <= 24 else { return nil }
        return value
    }
}
