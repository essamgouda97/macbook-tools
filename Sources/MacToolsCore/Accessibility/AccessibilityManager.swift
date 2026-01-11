import AppKit
import ApplicationServices

/// Manages Accessibility permission checks and requests.
public struct AccessibilityManager {

    /// Checks if the app has Accessibility permission.
    public static var hasPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Requests Accessibility permission, showing system dialog if needed.
    /// - Returns: Whether permission is granted after the check
    @discardableResult
    public static func requestPermission() -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Opens System Settings to the Accessibility pane.
    public static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Shows an alert explaining why Accessibility permission is needed.
    /// - Parameter appName: Name of the app to display in the alert
    @MainActor
    public static func showPermissionAlert(appName: String = "This app") {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "\(appName) needs Accessibility permission to detect triple-click events system-wide.\n\nPlease grant permission in System Settings → Privacy & Security → Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }
}
