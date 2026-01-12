#!/bin/bash
set -e

APP_NAME="FrancoTranslator"
BUNDLE_ID="com.macbooktools.francotranslator"
VERSION="1.0.0"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Building ${APP_NAME}...${NC}"

# Build release
swift build -c release

# Create app bundle structure
APP_DIR="build/${APP_NAME}.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy executable
cp ".build/release/${APP_NAME}" "$APP_DIR/Contents/MacOS/"

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

echo -e "${GREEN}✓ Built ${APP_NAME}.app${NC}"
echo ""
echo "To install:"
echo "  cp -r build/${APP_NAME}.app /Applications/"
echo ""
echo "To start at login:"
echo "  1. Open System Settings → General → Login Items"
echo "  2. Click '+' under 'Open at Login'"
echo "  3. Select ${APP_NAME} from Applications"
echo ""
echo "Or run now:"
echo "  open build/${APP_NAME}.app"
