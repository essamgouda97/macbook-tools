# MacBook Tools

A collection of productivity tools for macOS, built with Swift and SwiftUI.

## Tools

### FrancoTranslator

Triple-click anywhere to open a floating translator that converts Egyptian Franco-Arabic (Arabizi) to Egyptian Arabic using AI.

**Features:**
- System-wide triple-click activation
- Floating panel at cursor position
- Real-time translation via OpenAI GPT-4
- Conversation history
- Secure API key storage in Keychain
- Multiple ways to dismiss (Esc, click outside, Cmd+W, close button)

## Requirements

- macOS 14.0 (Sonoma) or later
- OpenAI API key
- Accessibility permission (for global event monitoring)

## Installation

### From Source

```bash
git clone https://github.com/yourusername/macbook_tools.git
cd macbook_tools
swift build -c release
```

The built app will be in `.build/release/FrancoTranslator`

## Configuration

### OpenAI API Key

1. Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Click the menu bar icon → Settings
3. Enter your API key (stored securely in macOS Keychain)

### Accessibility Permission

The app requires Accessibility permission to detect triple-clicks system-wide:

1. System Settings → Privacy & Security → Accessibility
2. Enable FrancoTranslator

## Usage

1. **Activate**: Triple-click (three rapid clicks) anywhere on screen
2. **Type**: Enter Franco-Arabic text in the floating panel
3. **Send**: Press Enter or click the send button
4. **View**: Arabic translation appears below
5. **Close**: Press Esc, click outside, or press Cmd+W

### Franco-Arabic Reference

| Franco | Arabic | Sound |
|--------|--------|-------|
| 2 | ء | glottal stop (hamza) |
| 3 | ع | ain |
| 5 / kh | خ | kh |
| 7 | ح | h (emphatic) |
| 8 / gh | غ | gh |
| 9 / q | ق | q |

### Examples

| Franco Input | Arabic Output |
|--------------|---------------|
| ezayak | إزيك |
| ana 3ayez akol | أنا عايز آكل |
| el7amdulellah | الحمد لله |
| ma3lesh | معلش |
| 2ahwa | قهوة |

## Development

### Project Structure

```
Sources/
├── MacToolsCore/     # Shared utilities across all tools
│   ├── Accessibility/
│   ├── EventMonitoring/
│   ├── UI/
│   └── Security/
└── FrancoTranslator/ # Franco translator app
    ├── Views/
    ├── ViewModels/
    └── Services/
```

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests
swift test
```

### Adding New Tools

1. Create new directory under `Sources/YourToolName/`
2. Add executable target to `Package.swift`
3. Import `MacToolsCore` for shared utilities

## Privacy

- API keys are stored locally in macOS Keychain
- Text is sent to OpenAI for translation (see [OpenAI privacy policy](https://openai.com/privacy))
- No data is collected or stored by this app beyond your local machine

## License

MIT License
