# AI Mac Tools

A collection of lightweight productivity tools for macOS, built with Swift and SwiftUI.

**[User Documentation →](DOCS.md)** | **[AI Agent Guidelines →](CLAUDE.md)**

## Current Tools

| Tool | Description | Trigger |
|------|-------------|---------|
| Franco → Arabic | Translates Egyptian Franco-Arabic to Arabic script | `⌘ + tap` |
| Terminal Helper | Natural language to shell commands | `⌘ + tap` |
| Spelling & Grammar | Fixes spelling and grammar errors | `⌘ + tap` |

## Quick Start

```bash
# Clone and install
git clone https://github.com/egouda/macbook_tools.git
cd macbook_tools
make install

# Run
open /Applications/FrancoTranslator.app
```

See [DOCS.md](DOCS.md) for usage instructions.

---

## Development

### Requirements

- macOS 14.0+ (Sonoma)
- Xcode Command Line Tools
- Swift 5.9+

### Build Commands

```bash
make help          # Show all commands
make build         # Debug build
make release       # Build .app bundle
make install       # Install to /Applications
make dev           # Run from source (for testing)
make reinstall     # Full rebuild + install + restart
```

### Development Workflow

```bash
# 1. Make changes
# 2. Test
make dev           # Runs from source, Ctrl+C to stop

# 3. Ship
make reinstall     # Rebuild, install, restart
```

### Project Structure

```
macbook_tools/
├── Sources/
│   ├── MacToolsCore/        # Shared library
│   │   ├── Accessibility/   # Permission helpers
│   │   ├── EventMonitoring/ # Hotkeys, gestures
│   │   ├── UI/              # Floating panels
│   │   └── Security/        # Keychain storage
│   └── FrancoTranslator/    # Main app
│       ├── Views/
│       ├── ViewModels/
│       ├── Models/
│       └── Services/
├── Scripts/                 # Build scripts
├── DOCS.md                  # User documentation
├── CLAUDE.md                # AI agent guidelines
└── Makefile
```

### Adding New Tools

See [CLAUDE.md](CLAUDE.md) for detailed guidelines on:
- Creating new tool modules
- Using MacToolsCore components
- Code patterns and best practices

---

## Configuration

### API Key

```bash
# Option 1: Environment variable (recommended)
export OPENAI_API_KEY="sk-..."

# Option 2: Via app Settings
# Menu bar → Settings → Enter API key
```

### Accessibility Permission

Required for global hotkey/gesture detection. Grant via:
**System Settings → Privacy & Security → Accessibility**

---

## Release Process

```bash
# 1. Update version if needed
# 2. Build release
make release
make zip

# 3. Create git tag
git tag v1.0.0
git push origin v1.0.0

# 4. Create GitHub release with zip
```

---

## Contributing

1. Fork the repo
2. Create a feature branch
3. Make changes (follow [CLAUDE.md](CLAUDE.md) guidelines)
4. Update [DOCS.md](DOCS.md) if user-facing
5. Submit PR

---

## License

MIT
