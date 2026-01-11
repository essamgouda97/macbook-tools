import AppKit
import SwiftUI

/// Controls the lifecycle of a floating panel.
/// Handles positioning, showing, hiding, and toggle behavior.
@MainActor
public final class FloatingPanelController<Content: View> {
    private var panel: FloatingPanel<Content>?
    private let contentBuilder: () -> Content
    private let panelSize: CGSize

    /// Whether the panel is currently visible
    public var isVisible: Bool {
        panel?.isVisible ?? false
    }

    /// Creates a panel controller.
    /// - Parameters:
    ///   - size: Size of the floating panel
    ///   - content: SwiftUI view builder for panel content
    public init(size: CGSize = CGSize(width: 350, height: 400), @ViewBuilder content: @escaping () -> Content) {
        self.panelSize = size
        self.contentBuilder = content
    }

    /// Shows the panel at the specified location.
    /// If panel is already visible, toggles it closed.
    /// - Parameter location: Screen coordinates (bottom-left origin)
    public func showPanel(at location: CGPoint) {
        // Toggle behavior: if already visible, close it
        if isVisible {
            hidePanel()
            return
        }

        let origin = calculatePanelOrigin(cursorLocation: location)
        let rect = NSRect(origin: origin, size: panelSize)

        panel = FloatingPanel(contentRect: rect, onClose: { [weak self] in
            self?.panel = nil
        }, content: contentBuilder)

        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Hides and destroys the panel.
    public func hidePanel() {
        panel?.closePanel()
        panel = nil
    }

    /// Calculates panel origin, clamping to screen bounds.
    private func calculatePanelOrigin(cursorLocation: CGPoint) -> CGPoint {
        // Find screen containing cursor
        let screen = NSScreen.screens.first { screen in
            NSMouseInRect(cursorLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens.first

        guard let screen = screen else {
            return cursorLocation
        }

        let screenFrame = screen.visibleFrame
        var origin = cursorLocation

        // Offset slightly from cursor
        origin.x += 10
        origin.y -= panelSize.height + 10

        // Clamp to screen bounds
        origin.x = min(origin.x, screenFrame.maxX - panelSize.width - 10)
        origin.x = max(origin.x, screenFrame.minX + 10)
        origin.y = min(origin.y, screenFrame.maxY - panelSize.height - 10)
        origin.y = max(origin.y, screenFrame.minY + 10)

        return origin
    }
}
