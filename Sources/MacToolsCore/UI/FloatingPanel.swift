import AppKit
import SwiftUI

/// Custom panel that can become key window
private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Singleton manager for a floating panel.
/// Panel appears at cursor and stays fixed - no following.
@MainActor
public final class PanelManager {
    public static let shared = PanelManager()

    private var panel: NSPanel?
    private var panelSize: CGSize = .zero
    private var escapeMonitors: [Any] = []
    private var onCloseCallback: (() -> Void)?

    // App tracking for auto-exit
    private var sourceAppBundleID: String?
    private var workspaceObserver: NSObjectProtocol?

    private init() {}

    // MARK: - Source App Tracking

    public func setSourceApp(bundleID: String?) {
        sourceAppBundleID = bundleID
    }

    // MARK: - Public API

    public var isVisible: Bool {
        panel?.isVisible ?? false
    }

    public func show<Content: View>(
        at location: CGPoint,
        size: CGSize,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        hide()

        panelSize = size
        onCloseCallback = onClose

        let origin = calculatePosition(cursor: location, size: size)
        let newPanel = createPanel(origin: origin, size: size, content: content())
        panel = newPanel

        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        setupEscapeMonitors()
        setupWorkspaceObserver()
        focusFirstTextField(in: newPanel)
    }

    public func hide() {
        removeEscapeMonitors()
        removeWorkspaceObserver()

        if let existingPanel = panel {
            existingPanel.orderOut(nil)
            existingPanel.close()
            panel = nil
        }

        sourceAppBundleID = nil

        if let callback = onCloseCallback {
            onCloseCallback = nil
            callback()
        }
    }

    // MARK: - Panel Creation

    private func createPanel<Content: View>(
        origin: CGPoint,
        size: CGSize,
        content: Content
    ) -> NSPanel {
        let panel = KeyablePanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.animationBehavior = .none

        panel.contentView = NSHostingView(rootView: content)

        return panel
    }

    // MARK: - Position (Fixed, with edge awareness)

    private func calculatePosition(cursor: CGPoint, size: CGSize) -> CGPoint {
        let offset: CGFloat = 12
        let padding: CGFloat = 10

        let screen = findScreen(containing: cursor)
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        // Default: panel to the right and below cursor
        var origin = CGPoint(x: cursor.x + offset, y: cursor.y - size.height - offset)

        // Flip horizontally if would go off right edge
        if origin.x + size.width > visibleFrame.maxX - padding {
            origin.x = cursor.x - size.width - offset
        }
        // Flip horizontally if would go off left edge
        if origin.x < visibleFrame.minX + padding {
            origin.x = cursor.x + offset
        }

        // Flip vertically if would go off bottom edge
        if origin.y < visibleFrame.minY + padding {
            origin.y = cursor.y + offset
        }
        // Flip vertically if would go off top edge
        if origin.y + size.height > visibleFrame.maxY - padding {
            origin.y = cursor.y - size.height - offset
        }

        return origin
    }

    private func findScreen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
    }

    // MARK: - Escape Key Monitors

    private func setupEscapeMonitors() {
        // Local escape
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [weak self] event in
            if event.keyCode == 53 {
                self?.hide()
                return nil
            }
            return event
        }) {
            escapeMonitors.append(monitor)
        }

        // Global escape
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: { [weak self] event in
            if event.keyCode == 53 {
                Task { @MainActor in self?.hide() }
            }
        }) {
            escapeMonitors.append(monitor)
        }
    }

    private func removeEscapeMonitors() {
        for monitor in escapeMonitors {
            NSEvent.removeMonitor(monitor)
        }
        escapeMonitors.removeAll()
    }

    // MARK: - Workspace Observer (Auto-exit on app switch)

    private func setupWorkspaceObserver() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let activatedBundleID = app.bundleIdentifier else { return }

                let ourBundleID = Bundle.main.bundleIdentifier

                // Hide if user switched to an app that's neither ours nor the source app
                if activatedBundleID != ourBundleID && activatedBundleID != self.sourceAppBundleID {
                    self.hide()
                }
            }
        }
    }

    private func removeWorkspaceObserver() {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            workspaceObserver = nil
        }
    }

    // MARK: - Focus Management

    private func focusFirstTextField(in panel: NSPanel) {
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        tryFocus(panel: panel, attempt: 0)
    }

    private func tryFocus(panel: NSPanel, attempt: Int) {
        guard attempt < 10, panel.isVisible else { return }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKey()

        if let textField = findFirstTextField(in: panel.contentView) {
            if panel.makeFirstResponder(textField) {
                NotificationCenter.default.post(name: .init("FocusTextField"), object: nil)
                return
            }
        }

        NotificationCenter.default.post(name: .init("FocusTextField"), object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self, weak panel] in
            guard let panel = panel else { return }
            self?.tryFocus(panel: panel, attempt: attempt + 1)
        }
    }

    private func findFirstTextField(in view: NSView?) -> NSView? {
        guard let view = view else { return nil }

        if view.acceptsFirstResponder {
            if view is NSTextField || view is NSTextView {
                return view
            }
            let className = String(describing: type(of: view))
            if className.contains("TextField") || className.contains("TextInput") || className.contains("Field") {
                return view
            }
        }

        for subview in view.subviews {
            if let found = findFirstTextField(in: subview) {
                return found
            }
        }

        return nil
    }
}
