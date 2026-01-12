# MacBook Tools

A collection of productivity tools for macOS, built with Swift and SwiftUI.

## Tools

### 🔤 FrancoTranslator

Instantly translate Egyptian Franco-Arabic (Arabizi) to Arabic script.

**Trigger:** `⌘ + double-click` anywhere, or customizable keyboard shortcut

**Features:**
- Floating panel appears at cursor
- Type Franco → get Arabic → auto-copied to clipboard
- Press `Esc` to close (or click outside, `Cmd+W`)
- Customizable keyboard shortcut in Settings

## Installation

### Quick Install

```bash
git clone https://github.com/egouda/macbook_tools.git
cd macbook_tools
make install
```

This builds and copies `FrancoTranslator.app` to `/Applications`.

### Start at Login

1. Open **System Settings → General → Login Items**
2. Click **+** under "Open at Login"
3. Select **FrancoTranslator** from Applications

## Usage

1. **Open:** Hold `⌘` and double-click anywhere
2. **Type:** Enter Franco-Arabic text (e.g., `ezayak`, `el7amdulellah`)
3. **Translate:** Press `Enter`
4. **Done:** Arabic appears and is auto-copied to clipboard
5. **Close:** Press `Esc`

### Franco-Arabic Reference

| Franco | Arabic | Sound |
|--------|--------|-------|
| 2 | ء | glottal stop |
| 3 | ع | ain |
| 5 / kh | خ | kh |
| 7 | ح | emphatic h |
| 8 / gh | غ | gh |
| 9 / q | ق | q |

## Requirements

- macOS 14.0+ (Sonoma)
- OpenAI API key (set `OPENAI_API_KEY` env var or enter in Settings)
- Accessibility permission (for global hotkeys)

## Configuration

### OpenAI API Key

Option 1: Environment variable (recommended)
```bash
# Add to ~/.zshrc
export OPENAI_API_KEY="sk-..."
```

Option 2: Via Settings
- Click menu bar icon → Settings → Enter API key

### Keyboard Shortcut

Default backup shortcut: `⌃⌥T` (Ctrl+Option+T)

Customize in Settings (menu bar → Settings).

## Development

```bash
make help          # Show all commands
make build         # Debug build
make run           # Build and run
make release       # Build .app bundle
make install       # Install to /Applications
make clean         # Clean build
```

### Adding New Tools

See [AGENTS.md](AGENTS.md) for guidelines on adding new tools to this repo.

## Project Structure

```
macbook_tools/
├── Makefile                 # Build commands
├── Package.swift            # SPM config
├── Sources/
│   ├── MacToolsCore/        # Shared library
│   └── FrancoTranslator/    # First tool
├── Scripts/                 # Build scripts
└── build/                   # Output .app bundles
```

## License

MIT
