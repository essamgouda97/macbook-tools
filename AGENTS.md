# AGENTS.md - AI Agent Guidelines

Guidelines for AI agents working on this macOS tools repository.

## Quick Start for Adding New Tools

```bash
# 1. Create tool directory
mkdir -p Sources/MyNewTool/{Views,ViewModels,Services}

# 2. Add to Package.swift
# Add new executable target that depends on MacToolsCore

# 3. Build & test
make build
make run APP_NAME=MyNewTool

# 4. Release
make release
make install
```

## Project Structure

```
macbook_tools/
├── Makefile                 # Build commands (make help)
├── Package.swift            # Swift Package Manager config
├── Sources/
│   ├── MacToolsCore/        # Shared library - USE THIS
│   │   ├── Accessibility/   # Permission helpers
│   │   ├── EventMonitoring/ # Hotkeys, gestures, clicks
│   │   ├── UI/              # FloatingPanel, controllers
│   │   └── Security/        # Keychain storage
│   └── [ToolName]/          # Each tool is separate
│       ├── Views/
│       ├── ViewModels/
│       └── Services/
├── Scripts/                 # Build scripts
└── build/                   # Output .app bundles
```

## MacToolsCore - Reusable Components

### Floating Panels
```swift
import MacToolsCore

let panel = FloatingPanelController(size: CGSize(width: 400, height: 300)) {
    MySwiftUIView()
}
panel.showPanel(at: NSEvent.mouseLocation)
panel.hidePanel()
```

### Global Hotkeys
```swift
let hotkey = GlobalHotkeyMonitor {
    // Triggered when hotkey pressed
}
hotkey.start()
```

### Cmd + Double-Click Trigger
```swift
let monitor = CmdDoubleClickMonitor { location in
    panel.showPanel(at: location)
}
monitor.start()
```

### Keychain Storage
```swift
// Store secrets securely
try KeychainManager.shared.save("value", forKey: "my_key")
let value = KeychainManager.shared.get(forKey: "my_key")
```

### Accessibility
```swift
if AccessibilityManager.hasPermission {
    // Good to go
} else {
    AccessibilityManager.requestPermission()
}
```

---

## Do

- **Use MacToolsCore** - Don't reinvent the wheel
- **Use Swift async/await** - Modern concurrency
- **Use @MainActor** - For all UI code
- **Use Keychain** - For any secrets/API keys
- **Provide escape mechanisms** - Esc, click outside, Cmd+W
- **Use `.floating` level** - Not modal panels
- **Read env vars first** - Then fall back to Keychain
- **Keep views simple** - Logic in ViewModels

## Don't

- **Don't force unwrap** - Use `guard let` or `if let`
- **Don't hardcode secrets** - Use env vars or Keychain
- **Don't block main thread** - Use async/await
- **Don't create modal panels** - Users must never be stuck
- **Don't skip Accessibility checks** - Required for global events
- **Don't use print()** - Use `os.Logger` if needed
- **Don't over-engineer** - Keep tools simple and focused

---

## Adding a New Tool

### 1. Create the structure
```
Sources/MyTool/
├── MyToolApp.swift          # @main entry point
├── AppDelegate.swift        # Menu bar, monitoring
├── Views/
│   └── MainView.swift
├── ViewModels/
│   └── MainViewModel.swift
└── Services/
    └── MyService.swift
```

### 2. Update Package.swift
```swift
.executableTarget(
    name: "MyTool",
    dependencies: ["MacToolsCore"]
)
```

### 3. Basic App Template
```swift
// MyToolApp.swift
import SwiftUI

@main
struct MyToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { SettingsView() }
    }
}

// AppDelegate.swift
import MacToolsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var monitor: CmdDoubleClickMonitor?
    private var panel: FloatingPanelController<MainView>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()

        panel = FloatingPanelController { MainView() }
        monitor = CmdDoubleClickMonitor { [weak self] loc in
            self?.panel?.showPanel(at: loc)
        }
        monitor?.start()
    }
}
```

---

## Build Commands

```bash
make help          # Show all commands
make build         # Debug build
make release       # Build .app bundle
make install       # Install to /Applications
make run           # Build and run
make clean         # Clean build artifacts
make zip           # Create release zip
```

---

## Common Patterns

### Menu Bar App (no dock icon)
```swift
NSApp.setActivationPolicy(.accessory)
```

### Floating Panel with Auto-Close
```swift
// In FloatingPanel - already implemented
// - Esc key closes
// - Click outside closes
// - Cmd+W closes
```

### API Key from Env → Keychain
```swift
let apiKey = ProcessInfo.processInfo.environment["MY_API_KEY"]
    ?? KeychainManager.shared.get(forKey: "my_api_key")
```

### Toggle Panel on Trigger
```swift
if panel.isVisible {
    panel.hidePanel()
} else {
    panel.showPanel(at: location)
}
```

---

## Testing Locally

```bash
# Run in debug mode
make run

# Or directly
swift run MyTool

# Build .app and open
make release
open build/MyTool.app
```

## Releasing

```bash
# Build, zip, and push tag
make release
make zip
git tag v1.0.0
git push origin v1.0.0
# Then create GitHub release with the zip
```
