# CLAUDE.md - AI Agent Guidelines

Guidelines for Claude and other AI agents working on this macOS tools repository.

## Documentation Structure

| File | Audience | Purpose |
|------|----------|---------|
| `DOCS.md` | End users | How to use the tools |
| `README.md` | Developers | How to build and contribute |
| `CLAUDE.md` | AI agents | Technical context and patterns |

**Important:** When adding features that change user-facing behavior, update `DOCS.md` with:
- New keyboard shortcuts
- New settings options
- New tools or tool capabilities
- Changed workflows

---

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

# 5. Update DOCS.md with user-facing changes!
```

## Project Structure

```
macbook_tools/
├── Makefile                 # Build commands (make help)
├── Package.swift            # Swift Package Manager config
├── DOCS.md                  # User documentation
├── README.md                # Developer documentation
├── CLAUDE.md                # AI agent guidelines (this file)
├── Sources/
│   ├── MacToolsCore/        # Shared library - USE THIS
│   │   ├── Accessibility/   # Permission helpers
│   │   ├── EventMonitoring/ # Hotkeys, gestures, clicks
│   │   ├── UI/              # FloatingPanel, controllers
│   │   └── Security/        # Keychain storage
│   └── [ToolName]/          # Each tool is separate
│       ├── Views/
│       ├── ViewModels/
│       ├── Models/
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
panel.pasteAndReturn()  // Close, return to previous app, paste clipboard
```

### Global Hotkeys
```swift
let hotkey = GlobalHotkeyMonitor {
    // Triggered when hotkey pressed
}
hotkey.start()
```

### Cmd + Tap Trigger
```swift
let monitor = CmdDoubleTapMonitor { location in
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
- **Update DOCS.md** - When adding user-facing features

## Don't

- **Don't force unwrap** - Use `guard let` or `if let`
- **Don't hardcode secrets** - Use env vars or Keychain
- **Don't block main thread** - Use async/await
- **Don't create modal panels** - Users must never be stuck
- **Don't skip Accessibility checks** - Required for global events
- **Don't use print()** - Use `os.Logger` if needed
- **Don't over-engineer** - Keep tools simple and focused
- **Don't forget docs** - User-facing changes need DOCS.md updates

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
├── Models/
│   └── MyModel.swift
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
    private var monitor: CmdDoubleTapMonitor?
    private var panel: FloatingPanelController<MainView>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()

        panel = FloatingPanelController { MainView() }
        monitor = CmdDoubleTapMonitor { [weak self] loc in
            self?.panel?.showPanel(at: loc)
        }
        monitor?.start()
    }
}
```

### 4. Update Documentation
After adding a new tool:
1. Add tool description to `DOCS.md` under "Tools" section
2. Add keyboard shortcuts to the reference table
3. Update any relevant workflow documentation

---

## Development Workflow

**For testing code changes:**
```bash
make dev           # Stop app, build, run from source (Ctrl+C to stop)
make restore       # Stop dev version, restart installed app
make status        # Show which version is running
```

**Typical workflow:**
```bash
# 1. Make code changes
# 2. Test them
make dev           # Runs from source, see changes immediately

# 3. When done testing, either:
make restore       # Go back to installed version (discard changes from install)
# OR
make install       # Ship changes to /Applications
make restore       # Restart the newly installed version
```

**Quick reference:**
```bash
make dev           # Test changes (runs from source)
make stop          # Stop any running version
make restore       # Restart installed app
make reinstall     # Stop → rebuild → install → restart (all in one)
make status        # Which version is running?
```

## All Build Commands

```bash
make help          # Show all commands
make build         # Debug build
make release       # Build .app bundle
make install       # Install to /Applications
make run           # Build and run (blocking)
make dev           # Build and run (stops existing, shows restore hint)
make stop          # Stop the app
make restore       # Restart installed app
make reinstall     # Full cycle: stop → install → restore
make clean         # Clean build artifacts
make zip           # Create release zip
make status        # Show running version
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

### Context-Aware Tool Selection
```swift
// Check source app and auto-select tool
let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
if let toolID = AppToolMappingStorage.shared.toolID(for: bundleID) {
    viewModel.selectTool(Tool.allTools.first { $0.id == toolID })
}
```

### UserDefaults Storage (Preferences)
```swift
// For non-sensitive settings
UserDefaults.standard.set(value, forKey: "my_key")
let value = UserDefaults.standard.string(forKey: "my_key")
```

### JSON-Codable Storage
```swift
// For structured data in UserDefaults
let data = try JSONEncoder().encode(myStruct)
UserDefaults.standard.set(data, forKey: "my_key")
```

---

## Releasing

```bash
# Build, zip, and push tag
make release
make zip
git tag v1.0.0
git push origin v1.0.0
# Then create GitHub release with the zip
```

---

## Checklist for Feature Completion

Before considering a feature complete:

- [ ] Code compiles without warnings
- [ ] Feature works as expected (manual testing)
- [ ] `DOCS.md` updated if user-facing
- [ ] Settings UI updated if new preferences
- [ ] Keyboard shortcuts documented
- [ ] `make reinstall` works cleanly
