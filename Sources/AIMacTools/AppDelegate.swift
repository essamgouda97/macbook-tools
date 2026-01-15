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
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single instance check - quit if another instance is running
        if isAnotherInstanceRunning() {
            NSApp.terminate(nil)
            return
        }

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

        // Only prompt for accessibility on first launch (onboarding)
        AccessibilityManager.requestPermission()

        let onboardingView = OnboardingView(tapToClickEnabled: TrackpadSettings.isTapToClickEnabled)
        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable]
        window.title = "Welcome to AI Mac Tools"
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        OnboardingManager.shared.markOnboardingSeen()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "hammer", accessibilityDescription: "AI Mac Tools") {
                button.image = image
            } else {
                button.title = "Tools"
            }
        }

        let menu = NSMenu()
        let openItem = NSMenuItem(title: "", action: #selector(showAtCenter), keyEquivalent: "")
        let openTitle = NSMutableAttributedString(string: "Open ")
        openTitle.append(NSAttributedString(
            string: "(⌘+tap)",
            attributes: [.foregroundColor: NSColor.secondaryLabelColor]
        ))
        openItem.attributedTitle = openTitle
        menu.addItem(openItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: ""))

        statusItem.menu = menu
    }

    private func checkAccessibilityAndStart() {
        // Don't prompt - just start monitoring
        // Permission prompt only happens during onboarding (first launch)
        // If permission missing, hotkey/tap won't work but app won't annoy user
        startMonitoring()
    }

    private func startMonitoring() {
        panelController = FloatingPanelController(size: CGSize(width: 320, height: 200)) { [weak self] in
            ChatBoxView(
                viewModel: self?.viewModel ?? TranslationViewModel(),
                onPasteAndReturn: { [weak self] in
                    self?.panelController?.pasteAndReturn()
                },
                onEscape: { [weak self] in
                    self?.panelController?.hidePanel()
                }
            )
        }

        // Primary: Cmd + tap opens at cursor
        doubleTapMonitor = CmdDoubleTapMonitor { [weak self] location in
            // Copy any selected text BEFORE we steal focus
            Self.copySelection()

            // Small delay for clipboard to update, then show panel
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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

    /// Copy current selection using CGEvent with hidden state (ignores held keys)
    private static func copySelection() {
        // Use .hidSystemState to create events independent of current keyboard state
        // This works even when Cmd is physically held from Cmd+tap
        let source = CGEventSource(stateID: .hidSystemState)

        // Cmd+C down
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cgSessionEventTap)
        }

        usleep(10000) // 10ms

        // Cmd+C up
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cgSessionEventTap)
        }
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
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Settings"
            window.styleMask = [.titled, .closable]
            window.center()
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
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

    /// Kill any other instances of this app
    private func isAnotherInstanceRunning() -> Bool {
        let myPID = ProcessInfo.processInfo.processIdentifier

        for app in NSWorkspace.shared.runningApplications {
            guard app.processIdentifier != myPID else { continue }

            // Match by name OR by executable path containing AIMacTools
            let isMatch = app.localizedName == "AIMacTools" ||
                          app.executableURL?.path.contains("AIMacTools") == true

            if isMatch {
                kill(app.processIdentifier, SIGKILL)
            }
        }

        usleep(200_000)  // 200ms for cleanup
        return false
    }
}
