import AppKit
import SwiftUI

/// A floating panel that appears above other windows.
/// Configured with multiple escape mechanisms to ensure user is never stuck.
public class FloatingPanel<Content: View>: NSPanel {
    private var clickOutsideMonitor: Any?
    private var onClose: (() -> Void)?

    /// Creates a floating panel with SwiftUI content.
    /// - Parameters:
    ///   - contentRect: Initial frame for the panel
    ///   - content: SwiftUI view builder for panel content
    ///   - onClose: Optional callback when panel closes
    public init(
        contentRect: NSRect,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onClose = onClose

        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        embedContent(content())
        setupClickOutsideMonitor()
    }

    private func configurePanel() {
        // Floating behavior
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Appearance
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        // Don't hide when app loses focus
        hidesOnDeactivate = false

        // Hide standard window buttons
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }

    private func embedContent(_ content: Content) {
        let hostingView = NSHostingView(rootView: content)
        contentView = hostingView
    }

    private func setupClickOutsideMonitor() {
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self = self, self.isVisible else { return }
            let clickLocation = NSEvent.mouseLocation
            if !self.frame.contains(clickLocation) {
                DispatchQueue.main.async {
                    self.closePanel()
                }
            }
        }
    }

    // MARK: - Escape Mechanisms

    /// Allow panel to become key window for text input
    public override var canBecomeKey: Bool { true }

    /// Handle Escape key to close panel
    public override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            closePanel()
        } else {
            super.keyDown(with: event)
        }
    }

    /// Handle Cmd+W to close panel
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w" {
            closePanel()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    /// Close the panel and clean up
    public func closePanel() {
        cleanup()
        close()
        onClose?()
    }

    private func cleanup() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }

    deinit {
        cleanup()
    }
}
