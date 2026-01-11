# AGENTS.md - AI Agent Guidelines

Guidelines for AI agents working on this macOS tools codebase.

## Project Overview

Swift/SwiftUI macOS tools repository. Primary tool is FrancoTranslator - a menu bar app that detects triple-click events and shows a floating translation panel.

## Architecture

- **MacToolsCore**: Shared library with reusable components
- **FrancoTranslator**: Menu bar app using SwiftUI + AppKit

## File Organization

```
Sources/ToolName/
├── Views/         # SwiftUI views
├── ViewModels/    # Business logic, state management
├── Services/      # API clients, external integrations
└── Resources/     # Assets, plists
```

---

## Do

### Code Style
- Use Swift 5.9+ features and async/await
- Use @MainActor for all UI-related code
- Follow Apple's Swift API Design Guidelines
- Add doc comments to public APIs only
- Use SwiftUI for views, AppKit only when necessary (NSPanel, NSEvent)
- Handle errors gracefully with user-friendly messages

### Architecture
- Keep business logic in ViewModels
- Use MVVM pattern for SwiftUI views
- Put shared/reusable code in MacToolsCore
- Use protocols for services to enable testing
- Use Combine or async/await for reactive patterns

### Security
- Store API keys in Keychain only (never UserDefaults)
- Validate user input before API calls
- Use HTTPS for all network requests
- Never log sensitive information

### UI/UX
- Always provide multiple ways to dismiss panels (Esc, click outside, Cmd+W)
- Never create modal/blocking panels that trap the user
- Use `.floating` level, not `.modalPanel`
- Clamp floating panels to screen bounds

### Testing
- Write unit tests for ViewModels and Services
- Mock network calls in tests
- Test error handling paths

---

## Don't

### Code Style
- Don't use force unwrapping (!) except for IBOutlets or tests
- Don't use implicitly unwrapped optionals unnecessarily
- Don't ignore compiler warnings
- Don't use `print()` for logging - use `os.Logger`
- Don't leave commented-out code
- Don't add unnecessary comments - code should be self-documenting

### Architecture
- Don't put business logic in Views
- Don't access Keychain directly from Views
- Don't create god objects - keep classes focused
- Don't use singletons except for truly global state

### Security
- Don't hardcode API keys or secrets
- Don't store API keys in UserDefaults or plain files
- Don't include secrets in git commits
- Don't disable App Transport Security

### macOS Specific
- Don't assume single screen - handle multiple displays
- Don't block the main thread with network calls
- Don't ignore Accessibility permission checks
- Don't create panels without escape mechanisms
- Don't use `.modalPanel` level for floating windows

---

## Key Patterns

### Global Event Monitoring
```swift
// Always use both global and local monitors for full coverage
let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
let localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
    handler(event)
    return event
}

// Always clean up in deinit
deinit {
    if let monitor = globalMonitor {
        NSEvent.removeMonitor(monitor)
    }
}
```

### Floating Panel Configuration
```swift
panel.level = .floating                              // Float above windows
panel.styleMask = [.nonactivatingPanel, .titled, .closable, .fullSizeContentView]
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
panel.isMovableByWindowBackground = true
panel.hidesOnDeactivate = false                      // Stay visible when app loses focus
```

### Escape Key Handling
```swift
override func keyDown(with event: NSEvent) {
    if event.keyCode == 53 {  // Escape key
        close()
    } else {
        super.keyDown(with: event)
    }
}
```

### Async Network Calls
```swift
Task { @MainActor in
    do {
        let result = try await service.translate(text)
        self.translation = result
    } catch {
        self.error = error.localizedDescription
    }
}
```

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Panel doesn't receive key events | Ensure `canBecomeKey` returns `true` |
| Triple-click not detected | Check Accessibility permission granted |
| API key not found | Verify Keychain service ID matches |
| Panel appears off-screen | Use screen bounds checking before positioning |
| Panel blocks interaction | Use `.nonactivatingPanel` style mask |

---

## Dependencies

| Package | Purpose |
|---------|---------|
| [MacPaw/OpenAI](https://github.com/MacPaw/OpenAI) | OpenAI API client |
| [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) | Keychain wrapper |

---

## Commands

```bash
swift build              # Debug build
swift build -c release   # Release build
swift test               # Run all tests
swift package resolve    # Resolve dependencies
```
