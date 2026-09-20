import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation

enum AnalyticsService {
    static var isDemo: Bool {
        AppSettings.isDemoData || DemoLaunch.shouldSeed
    }

    static func addStudent(billingMode: BillingMode, source: String, packageHours: Int = 0) {
        log("add_student", [
            "billing_mode": billingMode.rawValue,
            "source": source,
            "package_hours": packageHours
        ])
    }

    static func logLesson(
        billingMode: BillingMode,
        lessonType: LessonType,
        paidImmediately: Bool
    ) {
        log("log_lesson", [
            "billing_mode": billingMode.rawValue,
            "lesson_type": lessonType.rawValue,
            "paid_immediately": paidImmediately ? "true" : "false"
        ])
    }

    static func packagePurchase(hours: Int, source: String, hasAmount: Bool) {
        log("package_purchase", [
            "hours": hours,
            "source": source,
            "has_amount": hasAmount ? "true" : "false"
        ])
    }

    static func generateBill(billingMode: BillingMode?, lessonCount: Int) {
        var params: [String: Any] = ["lesson_count": lessonCount]
        if let billingMode {
            params["billing_mode"] = billingMode.rawValue
        }
        log("generate_bill", params)
    }

    static func markPaid(source: String, billingMode: BillingMode?, paymentMethod: PaymentMethod) {
        var params: [String: Any] = [
            "source": source,
            "payment_method": paymentMethod.rawValue
        ]
        if let billingMode {
            params["billing_mode"] = billingMode.rawValue
        }
        log("mark_paid", params)
    }

    static func exportCSV(source: String) {
        log("export_csv", ["source": source])
    }

    static func recordError(_ error: Error, context: String) {
        Crashlytics.crashlytics().setCustomValue(context, forKey: "error_context")
        Crashlytics.crashlytics().record(error: error)
    }

    private static func log(_ name: String, _ parameters: [String: Any] = [:]) {
        var merged = parameters
        merged["is_demo"] = isDemo ? "true" : "false"
        Analytics.logEvent(name, parameters: merged)
    }
}
