import SwiftUI
import UIKit

enum ShareService {
    static func temporaryCSVURL(
        from csv: String,
        filename: String = String(localized: "课酬记导出.csv")
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(safeFilename(filename))
        let content = "\u{FEFF}" + csv
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func safeFilename(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let sanitized = name.components(separatedBy: invalid).joined(separator: "_")
        return sanitized.isEmpty ? String(localized: "课酬记导出.csv") : sanitized
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: ((Bool) -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete?(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ActivityShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [Any]
    var onComplete: ((Bool) -> Void)?

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            ActivityShareSheet(items: items) { completed in
                onComplete?(completed)
                isPresented = false
            }
            .presentationDetents([.medium, .large])
            .ignoresSafeArea()
        }
    }
}

extension View {
    func activityShareSheet(
        isPresented: Binding<Bool>,
        items: [Any],
        onComplete: ((Bool) -> Void)? = nil
    ) -> some View {
        modifier(ActivityShareSheetModifier(isPresented: isPresented, items: items, onComplete: onComplete))
    }
}
