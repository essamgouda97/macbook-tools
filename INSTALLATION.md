# Installation Guide

## Download

Download the latest release from [GitHub Releases](https://github.com/egouda/macbook_tools/releases).

## Install from Release

1. **Download** `FrancoTranslator.zip` from the latest release
2. **Unzip** the file
3. **Move** `FrancoTranslator.app` to `/Applications`
4. **Open** the app

### First Launch

On first launch, macOS will ask for Accessibility permission:

1. Click **Open System Settings** when prompted
2. Find **FrancoTranslator** in the list
3. Toggle it **ON**
4. Restart the app if needed

## Install from Source

If you prefer to build from source:

```bash
git clone https://github.com/egouda/macbook_tools.git
cd macbook_tools
make install
```

## Configuration

### OpenAI API Key (Required)

**Option 1: Environment Variable (Recommended)**
```bash
# Add to ~/.zshrc
export OPENAI_API_KEY="sk-..."
source ~/.zshrc
```

**Option 2: Via Settings**
1. Click the menu bar icon (hammer)
2. Select **Settings**
3. Enter your API key
4. Click **Save**

Get your API key at: https://platform.openai.com/api-keys

### Start at Login (Optional)

1. Open **System Settings → General → Login Items**
2. Click **+** under "Open at Login"
3. Select **FrancoTranslator**

## Verify Installation

1. The app should appear in your menu bar (hammer icon)
2. Hold `⌘` and tap anywhere on screen
3. A floating panel should appear at your cursor

If the panel doesn't appear:
- Check Accessibility permission is granted
- Try the keyboard shortcut `⌃⌥T` (Ctrl+Option+T)

## Updating

### From Release

1. Quit the running app (menu bar → Quit)
2. Download the new release
3. Replace the app in `/Applications`
4. Reopen

### From Source

```bash
cd macbook_tools
git pull
make reinstall
```

## Uninstalling

```bash
# Remove the app
rm -rf /Applications/FrancoTranslator.app

# Remove settings (optional)
defaults delete com.macbooktools.FrancoTranslator

# Remove from Keychain (optional)
security delete-generic-password -s com.macbooktools
```

## Troubleshooting

### "App is damaged" or "can't be opened"

This happens with unsigned apps. Run:
```bash
xattr -cr /Applications/FrancoTranslator.app
```

### Panel doesn't open

1. Check **System Settings → Privacy & Security → Accessibility**
2. Ensure FrancoTranslator is enabled
3. Try restarting the app

### API errors

1. Verify your API key is correct
2. Check you have API credits at https://platform.openai.com
3. Try `echo $OPENAI_API_KEY` to verify env var is set

## Requirements

- macOS 14.0+ (Sonoma)
- OpenAI API key
- Internet connection (for AI processing)
