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
        let pid = app.processIdentifier

        hidePanel()

        // Activate the app
        app.activate()

        // Wait for app to be frontmost, then paste
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.15) {
            let source = CGEventSource(stateID: .combinedSessionState)

            // Cmd+V down
            if let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
                vDown.flags = .maskCommand
                vDown.post(tap: .cghidEventTap)
            }

            usleep(20000) // 20ms

            // Cmd+V up
            if let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
                vUp.flags = .maskCommand
                vUp.post(tap: .cghidEventTap)
            }
        }
    }
}
