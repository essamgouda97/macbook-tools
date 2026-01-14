import AppKit
import ApplicationServices

/// Manages Accessibility permission using Apple's standard flow.
public struct AccessibilityManager {

    /// Checks if the app has Accessibility permission.
    public static var hasPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Requests Accessibility permission using Apple's standard system dialog.
    /// Shows the native macOS prompt if permission not yet granted.
    /// - Returns: Whether permission is currently granted
    @discardableResult
    public static func requestPermission() -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Opens System Settings to the Accessibility pane.
    public static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
