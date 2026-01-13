import AppKit
import SwiftUI
import MacToolsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var cmdClickMonitor: CmdClickMonitor?
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
            if let image = NSImage(systemSymbolName: "hammer", accessibilityDescription: "MacBook Tools") {
                button.image = image
            } else {
                button.title = "Tools"
            }
        }

        let menu = NSMenu()

        // Tool shortcuts submenu
        let toolsMenu = NSMenu()
        for tool in Tool.allTools {
            let item = NSMenuItem(
                title: "\(tool.name) (⌘+\(tool.clickCount)×click)",
                action: #selector(showTool(_:)),
                keyEquivalent: ""
            )
            item.tag = tool.clickCount
            toolsMenu.addItem(item)
        }

        let toolsItem = NSMenuItem(title: "Open Tool", action: nil, keyEquivalent: "")
        toolsItem.submenu = toolsMenu
        menu.addItem(toolsItem)

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
                AccessibilityManager.showPermissionAlert(appName: "MacBook Tools")
            }

            // Try to start anyway - will work once permission granted
            startMonitoring()
        }
    }

    private func startMonitoring() {
        // Initialize panel controller
        panelController = FloatingPanelController(size: CGSize(width: 400, height: 300)) { [weak self] in
            ChatBoxView(viewModel: self?.viewModel ?? TranslationViewModel())
        }

        // Primary: Cmd + N clicks (2=Franco, 3=Terminal, 4=SpellFixer)
        cmdClickMonitor = CmdClickMonitor { [weak self] location, clickCount in
            DispatchQueue.main.async {
                self?.showToolAtLocation(clickCount: clickCount, location: location)
            }
        }
        cmdClickMonitor?.start()

        // Backup: keyboard hotkey (customizable in settings)
        hotkeyMonitor = GlobalHotkeyMonitor { [weak self] in
            self?.showToolAtCenter()
        }
        hotkeyMonitor?.start()
    }

    private func showToolAtLocation(clickCount: Int, location: CGPoint) {
        // Select tool based on click count (default to Franco if unknown)
        viewModel.selectTool(byClickCount: clickCount)
        panelController?.showPanel(at: location)
    }

    private func showToolAtCenter() {
        guard let screen = NSScreen.main else { return }
        let center = CGPoint(
            x: screen.frame.midX,
            y: screen.frame.midY
        )
        panelController?.showPanel(at: center)
    }

    @objc private func showTool(_ sender: NSMenuItem) {
        let clickCount = sender.tag
        viewModel.selectTool(byClickCount: clickCount)
        showToolAtCenter()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        cmdClickMonitor?.stop()
        hotkeyMonitor?.stop()
        panelController?.hidePanel()
    }
}
