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
        menu.addItem(NSMenuItem(title: "Open (⌘+tap)", action: #selector(showAtCenter), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func checkAccessibilityAndStart() {
        // Don't prompt - just start monitoring
        // Permission prompt only happens during onboarding (first launch)
        // If permission missing, hotkey/tap won't work but app won't annoy user
        startMonitoring()
    }

    private func startMonitoring() {
        panelController = FloatingPanelController(size: CGSize(width: 400, height: 300)) { [weak self] in
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
            // No DispatchQueue.main.async here - CmdDoubleTapMonitor already dispatches to main
            self?.autoSelectToolForCurrentApp()
            self?.panelController?.showPanel(at: location)
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
