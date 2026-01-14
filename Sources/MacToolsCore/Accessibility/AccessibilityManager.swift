import AppKit
import ApplicationServices

/// Manages Accessibility permission using Apple's standard flow.
public struct AccessibilityManager {

    /// Checks if the app has Accessibility permission.
    public static var hasPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Requests Accessibility permission using Apple's standard system dialog.
    /// Only shows the prompt if permission is not already granted.
    /// - Returns: Whether permission is currently granted
    @discardableResult
    public static func requestPermission() -> Bool {
        // First check without prompting
        if AXIsProcessTrusted() {
            return true
        }

        // Only prompt if not already granted
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
