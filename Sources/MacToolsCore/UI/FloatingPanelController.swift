@preconcurrency import AppKit
import SwiftUI

@MainActor
public final class FloatingPanelController<Content: View> {
    private let contentBuilder: () -> Content
    private let panelSize: CGSize
    private var previousApp: NSRunningApplication?

    public init(size: CGSize = CGSize(width: 350, height: 400), @ViewBuilder content: @escaping () -> Content) {
        self.panelSize = size
        self.contentBuilder = content
    }

    public func showPanel(at location: CGPoint) {
        // Capture previous app BEFORE we activate - exclude our own app
        let currentApp = NSWorkspace.shared.frontmostApplication
        if currentApp?.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp = currentApp
        }

        // Tell PanelManager which app we came from (for auto-exit on app switch)
        PanelManager.shared.setSourceApp(bundleID: previousApp?.bundleIdentifier)

        PanelManager.shared.show(
            at: location,
            size: panelSize,
            onClose: nil,
            content: contentBuilder
        )
    }

    public func hidePanel() {
        PanelManager.shared.hide()
    }

    public func pasteAndReturn() {
        guard let app = previousApp else { hidePanel(); return }

        // Get the text to paste from clipboard
        guard let text = NSPasteboard.general.string(forType: .string) else {
            hidePanel()
            return
        }

        hidePanel()
        app.activate()

        // Type the text directly (avoids bracketed paste mode in Terminal)
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.15) {
            Self.typeText(text)
        }
    }

    /// Type text character by character using CGEvent (avoids bracketed paste)
    private nonisolated static func typeText(_ text: String) {
        let source = CGEventSource(stateID: .combinedSessionState)

        for char in text {
            let str = String(char)
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                var buffer = [UniChar](str.utf16)
                event.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: &buffer)
                event.post(tap: .cghidEventTap)
            }
            usleep(500) // 0.5ms between characters for reliability
        }
    }
}
