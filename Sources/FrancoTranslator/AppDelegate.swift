import AppKit
import SwiftUI
import MacToolsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var doubleTapMonitor: CmdDoubleTapMonitor?
    private var hotkeyMonitor: GlobalHotkeyMonitor?
    private var panelController: FloatingPanelController<ChatBoxView>?
    private let viewModel = TranslationViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - menu bar only
        NSApp.setActivationPolicy(.accessory)

        setupMenuBar()
        checkAccessibilityAndStart()
        showOnboardingIfNeeded()

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

    private func showOnboardingIfNeeded() {
        guard OnboardingManager.shared.shouldShowOnboarding else { return }

        let onboardingView = OnboardingView(tapToClickEnabled: TrackpadSettings.isTapToClickEnabled)
        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable]
        window.title = "Welcome to MacBook Tools"
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        OnboardingManager.shared.markOnboardingSeen()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "hammer", accessibilityDescription: "MacBook Tools") {
                button.image = image
            } else {
                button.title = "Tools"
            }
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open (⌘+tap)", action: #selector(showAtCenter), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func checkAccessibilityAndStart() {
        // Request permission - macOS shows its standard dialog if needed
        AccessibilityManager.requestPermission()
        startMonitoring()
    }

    private func startMonitoring() {
        panelController = FloatingPanelController(size: CGSize(width: 400, height: 300)) { [weak self] in
            ChatBoxView(
                viewModel: self?.viewModel ?? TranslationViewModel(),
                onPasteAndReturn: { [weak self] in
                    self?.panelController?.pasteAndReturn()
                }
            )
        }

        // Primary: Cmd + tap opens at cursor
        doubleTapMonitor = CmdDoubleTapMonitor { [weak self] location in
            DispatchQueue.main.async {
                self?.autoSelectToolForCurrentApp()
                self?.panelController?.showPanel(at: location)
            }
        }
        doubleTapMonitor?.start()

        // Backup: keyboard hotkey (customizable in settings)
        hotkeyMonitor = GlobalHotkeyMonitor { [weak self] in
            self?.showAtCenter()
        }
        hotkeyMonitor?.start()
    }

    /// Auto-select the appropriate tool based on the frontmost app
    private func autoSelectToolForCurrentApp() {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
              let toolID = AppToolMappingStorage.shared.toolID(for: bundleID),
              let tool = Tool.allTools.first(where: { $0.id == toolID }) else {
            return
        }
        viewModel.selectTool(tool)
    }

    @objc private func showAtCenter() {
        autoSelectToolForCurrentApp()
        guard let screen = NSScreen.main else { return }
        let center = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
        panelController?.showPanel(at: center)
    }

    @objc private func checkForUpdates() {
        Task {
            await UpdateService.shared.checkForUpdates()
        }
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        doubleTapMonitor?.stop()
        hotkeyMonitor?.stop()
        panelController?.hidePanel()
    }
}
