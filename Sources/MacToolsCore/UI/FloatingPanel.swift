import AppKit
import SwiftUI

/// Custom panel that can become key window
private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Singleton manager for a floating panel that follows the cursor.
///
/// Uses Apple's recommended patterns:
/// - NSEvent monitors for escape key (both local and global)
/// - NSEvent monitors for mouse movement (not Timer-based polling)
/// - Proper NSPanel configuration for floating auxiliary windows
@MainActor
public final class PanelManager {
    public static let shared = PanelManager()

    private var panel: NSPanel?
    private var panelSize: CGSize = .zero
    private var eventMonitors: [Any] = []
    private var onCloseCallback: (() -> Void)?
    private var lastMouseLocation: CGPoint = .zero
    private var initialPosition: Bool = true

    private init() {}

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
        lastMouseLocation = location
        initialPosition = true

        let origin = calculatePanelOrigin(for: location, size: size)
        let newPanel = createPanel(origin: origin, size: size, content: content())
        panel = newPanel

        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        setupEventMonitors()
        focusFirstTextField(in: newPanel)
    }

    public func hide() {
        removeEventMonitors()

        if let existingPanel = panel {
            existingPanel.orderOut(nil)
            existingPanel.close()
            panel = nil
        }

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

        // Floating panel configuration
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false

        // Appearance
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true

        // Animation for smooth movement
        panel.animationBehavior = .utilityWindow

        panel.contentView = NSHostingView(rootView: content)

        return panel
    }

    // MARK: - Event Monitors

    private func setupEventMonitors() {
        // Local escape - when our app is focused
        let localEscapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hide()
                return nil // consume the event
            }
            return event
        }
        if let monitor = localEscapeMonitor {
            eventMonitors.append(monitor)
        }

        // Global escape - when other apps focused
        let globalEscapeMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                Task { @MainActor in
                    self?.hide()
                }
            }
        }
        if let monitor = globalEscapeMonitor {
            eventMonitors.append(monitor)
        }

        // Mouse movement monitor - global (when app isn't focused)
        let globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            Task { @MainActor in
                self?.updatePanelPosition()
            }
        }
        if let monitor = globalMouseMonitor {
            eventMonitors.append(monitor)
        }

        // Mouse movement monitor - local (when app is focused)
        let localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.updatePanelPosition()
            return event
        }
        if let monitor = localMouseMonitor {
            eventMonitors.append(monitor)
        }
    }

    private func removeEventMonitors() {
        for monitor in eventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        eventMonitors.removeAll()
    }

    // MARK: - Position Management

    private func updatePanelPosition() {
        guard let panel = panel, panel.isVisible else { return }

        let mouseLocation = NSEvent.mouseLocation

        // Calculate movement delta from last position
        let dx = mouseLocation.x - lastMouseLocation.x
        let dy = mouseLocation.y - lastMouseLocation.y

        // Skip tiny movements to reduce jitter
        guard abs(dx) > 2 || abs(dy) > 2 else { return }

        // Move panel by the same delta as mouse movement
        var newOrigin = panel.frame.origin
        newOrigin.x += dx
        newOrigin.y += dy

        // Clamp to screen bounds
        newOrigin = clampOriginToScreen(newOrigin, size: panelSize, mouseLocation: mouseLocation)

        panel.setFrameOrigin(newOrigin)
        lastMouseLocation = mouseLocation
    }

    private func clampOriginToScreen(_ origin: CGPoint, size: CGSize, mouseLocation: CGPoint) -> CGPoint {
        let screenPadding: CGFloat = 10
        var result = origin

        let screen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main

        guard let visibleFrame = screen?.visibleFrame else {
            return result
        }

        result.x = max(visibleFrame.minX + screenPadding, result.x)
        result.x = min(visibleFrame.maxX - size.width - screenPadding, result.x)
        result.y = max(visibleFrame.minY + screenPadding, result.y)
        result.y = min(visibleFrame.maxY - size.height - screenPadding, result.y)

        return result
    }

    private func calculatePanelOrigin(for mouseLocation: CGPoint, size: CGSize) -> CGPoint {
        let cursorOffset: CGFloat = 15
        let screenPadding: CGFloat = 10

        var origin = CGPoint(
            x: mouseLocation.x + cursorOffset,
            y: mouseLocation.y - size.height - cursorOffset
        )

        // Find the screen containing the mouse cursor
        let screen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main

        guard let visibleFrame = screen?.visibleFrame else {
            return origin
        }

        // Clamp to screen bounds
        origin.x = max(visibleFrame.minX + screenPadding, origin.x)
        origin.x = min(visibleFrame.maxX - size.width - screenPadding, origin.x)
        origin.y = max(visibleFrame.minY + screenPadding, origin.y)
        origin.y = min(visibleFrame.maxY - size.height - screenPadding, origin.y)

        return origin
    }

    // MARK: - Focus Management

    private func focusFirstTextField(in panel: NSPanel) {
        // Activate the app and make panel key
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        // Keep trying to focus
        tryFocus(panel: panel, attempt: 0)
    }

    private func tryFocus(panel: NSPanel, attempt: Int) {
        guard attempt < 20, panel.isVisible else { return }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKey()

        // Find and focus the text field
        if let textField = findFirstTextField(in: panel.contentView) {
            if panel.makeFirstResponder(textField) {
                NotificationCenter.default.post(name: .init("FocusTextField"), object: nil)
                return
            }
        }

        // Notify SwiftUI
        NotificationCenter.default.post(name: .init("FocusTextField"), object: nil)

        // Try again
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak panel] in
            guard let panel = panel else { return }
            self?.tryFocus(panel: panel, attempt: attempt + 1)
        }
    }

    private func findFirstTextField(in view: NSView?) -> NSView? {
        guard let view = view else { return nil }

        // Check if this view accepts first responder and can handle text
        if view.acceptsFirstResponder {
            // NSTextField, NSTextView, or SwiftUI's wrapped text field
            if view is NSTextField || view is NSTextView {
                return view
            }
            // SwiftUI wraps TextField in a special view - check class name
            let className = String(describing: type(of: view))
            if className.contains("TextField") || className.contains("TextInput") || className.contains("Field") {
                return view
            }
        }

        // Search subviews depth-first
        for subview in view.subviews {
            if let found = findFirstTextField(in: subview) {
                return found
            }
        }

        return nil
    }

    /// Find any view that accepts first responder (fallback)
    private func findFirstResponderCandidate(in view: NSView?) -> NSView? {
        guard let view = view else { return nil }

        for subview in view.subviews {
            if subview.acceptsFirstResponder && subview.canBecomeKeyView {
                return subview
            }
            if let found = findFirstResponderCandidate(in: subview) {
                return found
            }
        }

        return nil
    }
}

// MARK: - Virtual Key Codes

/// Virtual key code for Escape key (Carbon.HIToolbox)
private let kVK_Escape: UInt16 = 0x35
