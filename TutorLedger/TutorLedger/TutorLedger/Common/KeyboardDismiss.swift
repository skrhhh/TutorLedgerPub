import SwiftUI
import UIKit

enum KeyboardDismiss {
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

// MARK: - Global background tap (installed once on key window)

private final class KeyboardDismissInstaller: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissInstaller()

    private weak var installedWindow: UIWindow?

    func install(on window: UIWindow) {
        guard installedWindow !== window else { return }
        installedWindow = window

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        KeyboardDismiss.dismiss()
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !isTextInputView(touch.view)
    }

    private func isTextInputView(_ view: UIView?) -> Bool {
        var current = view
        while let v = current {
            if v is UITextField || v is UITextView {
                return true
            }
            let name = String(describing: type(of: v))
            if name.contains("TextField") || name.contains("TextView") || name.contains("TextEditor") {
                return true
            }
            current = v.superview
        }
        return false
    }
}

private struct KeyboardDismissInstallerView: UIViewRepresentable {
    func makeUIView(context: Context) -> InstallerAnchorView {
        InstallerAnchorView()
    }

    func updateUIView(_ uiView: InstallerAnchorView, context: Context) {}
}

private final class InstallerAnchorView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window {
            KeyboardDismissInstaller.shared.install(on: window)
        }
    }
}

// MARK: - View modifiers

extension View {
    /// Installs a window-level tap gesture to dismiss the keyboard when tapping outside text inputs.
    func installKeyboardDismissOnTap() -> some View {
        background(KeyboardDismissInstallerView())
    }

    /// Scroll + tap-to-dismiss for scrollable form pages.
    func tlKeyboardDismissibleScroll() -> some View {
        scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    KeyboardDismiss.dismiss()
                }
            )
    }
}
