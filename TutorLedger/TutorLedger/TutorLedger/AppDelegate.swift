import FirebaseCore
import FirebaseCrashlytics
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        Crashlytics.crashlytics().setCustomValue(version, forKey: "app_version")
        return true
    }
}
