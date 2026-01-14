# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2025-01-13

### New Features

- **Context-Aware Tool Selection**: Auto-selects the right tool based on source app
  - Terminal/iTerm/Warp/VS Code/Xcode → Terminal Helper
  - Safari/Chrome/Notes/Slack → Spelling & Grammar
  - 30+ default app mappings included
  - Fully customizable in Settings

- **Paste and Return**: Press `⌘V` to close panel, return to previous app, and paste result automatically

- **Settings UI Improvements**
  - App mappings editor (add, remove, reset defaults)
  - Visual permission status

### Documentation

- Comprehensive user guide (DOCS.md)
- Installation guide for releases (INSTALLATION.md)
- Developer documentation (README.md)
- AI agent guidelines (CLAUDE.md)
- GitHub issue templates

### Developer Experience

- `make github-release v=X.Y.Z` - one command to create GitHub release
- `make reinstall` - rebuild + install + restart in one command

---

## [1.0.0] - 2025-01-12

### Features

- **Multi-Tool Interface**: Three AI-powered tools in one floating panel
  - **Franco → Arabic**: Translates Egyptian Franco-Arabic (Arabizi) to Arabic script
  - **Terminal Helper**: Converts natural language to shell commands (loads your ~/.zshrc)
  - **Spelling & Grammar**: Fixes spelling and grammar errors

- **Context-Aware Tool Selection**: Auto-selects the right tool based on source app
  - Terminal/iTerm/Warp/VS Code → Terminal Helper
  - Safari/Chrome/Notes/Slack → Spelling & Grammar
  - Customizable in Settings with 30+ default app mappings

- **Seamless Workflow**
  - `⌘ + tap` anywhere to open panel at cursor
  - Results auto-copied to clipboard
  - `⌘V` closes panel, returns to previous app, and pastes
  - `Esc` closes without pasting

- **Keyboard-First Design**
  - `⌘1/2/3` to switch tools
  - `Tab` to cycle tools
  - Customizable global hotkey (default: `⌃⌥T`)

- **Clean Settings UI**
  - App mappings editor with add/delete/reset
  - Hotkey recorder
  - API key management (Keychain storage)
  - Accessibility permission status

### Technical

- Built with Swift 5.9 and SwiftUI
- Menu bar app (no dock icon)
- Floating NSPanel with auto-close on click outside
- Notification-based paste timing for reliability
- UserDefaults for preferences, Keychain for secrets

### Requirements

- macOS 14.0+ (Sonoma)
- OpenAI API key
- Accessibility permission
