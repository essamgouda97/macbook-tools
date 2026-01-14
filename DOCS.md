# AI Mac Tools - User Guide

A lightweight productivity toolbox for macOS. Hold `⌘` and tap anywhere to open a floating panel with AI-powered tools.

## Installation

```bash
git clone https://github.com/egouda/macbook_tools.git
cd macbook_tools
make install
```

The app installs to `/Applications/FrancoTranslator.app` and runs as a menu bar app (no dock icon).

### Start at Login

1. Open **System Settings → General → Login Items**
2. Click **+** under "Open at Login"
3. Select **FrancoTranslator** from Applications

### Requirements

- macOS 14.0+ (Sonoma)
- OpenAI API key
- Accessibility permission (granted on first launch)

---

## Quick Start

| Action | Result |
|--------|--------|
| `⌘ + tap` | Open panel at cursor |
| Type + `Enter` | Process with selected tool |
| `⌘V` | Close panel, paste result in previous app |
| `Esc` | Close panel (no paste) |
| `⌘1/2/3` | Switch tools |
| `Tab` | Cycle through tools |

---

## Tools

### 1. Franco → Arabic (`⌘1`)

Translates Egyptian Franco-Arabic (Arabizi) to Arabic script.

**Example:**
```
Input:  ezayak ya 7abeby
Output: إزيك يا حبيبي
```

**Franco Reference:**

| Franco | Arabic | Sound |
|--------|--------|-------|
| 2 | ء | glottal stop (e.g., so2al → سؤال) |
| 3 | ع | ain (e.g., 3ala → على) |
| 5 / kh | خ | kh (e.g., 5alas → خلاص) |
| 7 | ح | emphatic h (e.g., 7abibi → حبيبي) |
| 8 / gh | غ | gh (e.g., 8ali → غالي) |
| 9 / q | ق | q (e.g., 9alb → قلب) |

---

### 2. Terminal Helper (`⌘2`)

Converts natural language to shell commands. Loads your `~/.zshrc` for context (aliases, functions).

**Examples:**
```
Input:  find all python files modified today
Output: find . -name "*.py" -mtime 0

Input:  compress this folder
Output: tar -czvf folder.tar.gz folder/

Input:  show disk usage by folder
Output: du -sh */ | sort -hr
```

---

### 3. Spelling & Grammar (`⌘3`)

Fixes spelling and grammar errors while preserving your voice.

**Example:**
```
Input:  i cant beleive this isnt working, its definately broken
Output: I can't believe this isn't working, it's definitely broken
```

---

## Context-Aware Tool Selection

The app automatically selects the right tool based on which app you triggered it from:

| Source App | Auto-Selected Tool |
|------------|-------------------|
| Terminal, iTerm, Warp, VS Code, Xcode | Terminal Helper |
| Safari, Chrome, Arc, Firefox | Spelling & Grammar |
| Notes, Pages, Word, Notion, Obsidian | Spelling & Grammar |
| Slack, Discord, Messages, Telegram | Spelling & Grammar |
| Other apps | Franco (default) |

You can always switch manually with `⌘1/2/3` or `Tab`.

### Customizing App Mappings

1. Click the menu bar icon → **Settings**
2. Under **App Mappings**, you'll see all configured apps
3. Change the tool for any app using the dropdown
4. Click **Add App** to add running apps not in the list
5. Click **Reset Defaults** to restore built-in mappings

---

## Workflow: Paste and Return

The smoothest workflow:

1. You're typing in any app (e.g., Terminal, Slack, Notes)
2. `⌘ + tap` → panel opens, previous app remembered
3. Type your input, press `Enter`
4. Result appears and is **auto-copied** to clipboard
5. Press `⌘V` → panel closes, focuses previous app, pastes automatically

This means: **trigger → type → enter → paste** — all without leaving your keyboard.

---

## Settings

Access via menu bar icon → **Settings** (or `⌘,`)

### Keyboard Shortcut

Default: `⌃⌥T` (Ctrl+Option+T)

Click the shortcut box and press your desired key combination to change it.

### OpenAI API Key

**Option 1: Environment Variable (Recommended)**
```bash
# Add to ~/.zshrc
export OPENAI_API_KEY="sk-..."
```

**Option 2: Via Settings**
1. Open Settings
2. Paste your API key
3. Click Save

Get your API key at: https://platform.openai.com/api-keys

### Accessibility Permission

Required for `⌘ + tap` detection. On first launch, macOS will prompt you. If denied:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Find **FrancoTranslator** and enable it
3. Restart the app

---

## Keyboard Shortcuts Reference

### In the Panel

| Shortcut | Action |
|----------|--------|
| `Enter` | Process input |
| `⌘V` | Close, return to previous app, paste |
| `Esc` | Close (no paste) |
| `⌘W` | Close (no paste) |
| `⌘1` | Select Franco tool |
| `⌘2` | Select Terminal tool |
| `⌘3` | Select Spelling tool |
| `Tab` | Cycle to next tool |

### Global

| Shortcut | Action |
|----------|--------|
| `⌘ + tap` | Open panel at cursor |
| `⌃⌥T` (default) | Open panel at screen center |

---

## Tips

### For Best Results

- **Franco:** Write phonetically as you'd text. Numbers represent Arabic letters.
- **Terminal:** Be specific. "Delete all .log files older than 7 days" works better than "clean logs".
- **Spelling:** Paste full sentences for context-aware corrections.

### Pro Tips

- **Tap to Click:** Enable in System Settings → Trackpad for smoother `⌘ + tap` trigger
- **Quick access:** The panel remembers your last used tool (unless auto-selected by app)
- **Clipboard workflow:** Results are always copied, so you can `⌘V` even after closing with `Esc`

---

## Troubleshooting

### Panel doesn't open on ⌘ + tap

1. Check Accessibility permission (System Settings → Privacy & Security → Accessibility)
2. Enable "Tap to click" in Trackpad settings (if using trackpad tap)
3. Try the keyboard shortcut (`⌃⌥T`) as a backup

### "API key not found" error

1. Check if `OPENAI_API_KEY` is set: `echo $OPENAI_API_KEY`
2. Or add it via Settings
3. Restart the app after adding env var

### App not starting

```bash
# Check if running
pgrep -l FrancoTranslator

# Restart
killall FrancoTranslator
open /Applications/FrancoTranslator.app
```

### Reset all settings

```bash
defaults delete com.macbooktools.FrancoTranslator
```

---

## Updating

```bash
cd macbook_tools
git pull
make reinstall
```

This stops the running app, rebuilds, installs, and restarts.

---

## Uninstalling

```bash
# Remove app
rm -rf /Applications/FrancoTranslator.app

# Remove settings (optional)
defaults delete com.macbooktools.FrancoTranslator

# Remove from Keychain (optional)
security delete-generic-password -s com.macbooktools
```

---

## License

MIT
