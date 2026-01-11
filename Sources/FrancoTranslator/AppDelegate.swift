import AppKit
import SwiftUI
import MacToolsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var cmdDoubleClickMonitor: CmdDoubleClickMonitor?
    private var hotkeyMonitor: GlobalHotkeyMonitor?
    private var panelController: FloatingPanelController<ChatBoxView>?
    private let viewModel = TranslationViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - menu bar only
        NSApp.setActivationPolicy(.accessory)

        setupMenuBar()
        checkAccessibilityAndStart()

        // Listen for hotkey changes
        NotificationCenter.default.addObserver(
            forName: .hotkeyChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hotkeyMonitor?.start()
            }
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Try system symbol first, fallback to text
            if let image = NSImage(systemSymbolName: "character.bubble", accessibilityDescription: "Franco Translator") {
                button.image = image
            } else {
                button.title = "عـ"
            }
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Translator (⌘+double-click)", action: #selector(showTranslatorAtCenter), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func checkAccessibilityAndStart() {
        if AccessibilityManager.hasPermission {
            startMonitoring()
        } else {
            // Request permission
            AccessibilityManager.requestPermission()

            // Show explanation
            Task { @MainActor in
                AccessibilityManager.showPermissionAlert(appName: "FrancoTranslator")
            }

            // Try to start anyway - will work once permission granted
            startMonitoring()
        }
    }

    private func startMonitoring() {
        // Initialize panel controller
        panelController = FloatingPanelController(size: CGSize(width: 380, height: 280)) { [weak self] in
            ChatBoxView(viewModel: self?.viewModel ?? TranslationViewModel())
        }

        // Primary: Cmd + double-click
        cmdDoubleClickMonitor = CmdDoubleClickMonitor { [weak self] location in
            DispatchQueue.main.async {
                self?.panelController?.showPanel(at: location)
            }
        }
        cmdDoubleClickMonitor?.start()

        // Backup: keyboard hotkey (customizable in settings)
        hotkeyMonitor = GlobalHotkeyMonitor { [weak self] in
            self?.showTranslatorAtCenter()
        }
        hotkeyMonitor?.start()
    }

    @objc private func menuBarClicked() {
        // Menu will show automatically
    }

    @objc private func showTranslatorAtCenter() {
        guard let screen = NSScreen.main else { return }
        let center = CGPoint(
            x: screen.frame.midX,
            y: screen.frame.midY
        )
        panelController?.showPanel(at: center)
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        cmdDoubleClickMonitor?.stop()
        hotkeyMonitor?.stop()
        panelController?.hidePanel()
    }
}
