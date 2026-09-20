import StoreKit
import UIKit

enum AppReviewPrompt {
    static func askIfEligible(lessonCount: Int, justCreatedBill: Bool = false) {
        guard !AppSettings.hasRequestedReview else { return }
        let eligible = (justCreatedBill && lessonCount >= 3) || lessonCount >= 5
        guard eligible else { return }

        AppSettings.hasRequestedReview = true
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
            else { return }
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
