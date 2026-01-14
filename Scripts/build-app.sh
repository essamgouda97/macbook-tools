#!/bin/bash
set -e

APP_NAME="FrancoTranslator"

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

# Copy Info.plist
cp "Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

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
