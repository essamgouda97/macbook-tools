.PHONY: all build release install uninstall clean run test help

# Configuration
APP_NAME = FrancoTranslator
BUNDLE_ID = com.macbooktools.francotranslator
VERSION = 1.0.0
BUILD_DIR = build
INSTALL_DIR = /Applications

# Colors
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[0;33m
NC = \033[0m

help: ## Show this help
	@echo "MacBook Tools - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

all: build ## Build debug version

build: ## Build debug version
	@echo "$(BLUE)Building debug...$(NC)"
	swift build
	@echo "$(GREEN)✓ Debug build complete$(NC)"

release: ## Build release .app bundle
	@echo "$(BLUE)Building release...$(NC)"
	swift build -c release
	@mkdir -p $(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS
	@mkdir -p $(BUILD_DIR)/$(APP_NAME).app/Contents/Resources
	@cp .build/release/$(APP_NAME) $(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS/
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<plist version="1.0"><dict>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<key>CFBundleExecutable</key><string>$(APP_NAME)</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<key>CFBundleIdentifier</key><string>$(BUNDLE_ID)</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<key>CFBundleName</key><string>$(APP_NAME)</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<key>CFBundleVersion</key><string>$(VERSION)</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<key>CFBundleShortVersionString</key><string>$(VERSION)</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<key>LSMinimumSystemVersion</key><string>14.0</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<key>LSUIElement</key><true/>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<key>NSHighResolutionCapable</key><true/>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '</dict></plist>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo -n 'APPL????' > $(BUILD_DIR)/$(APP_NAME).app/Contents/PkgInfo
	@echo "$(GREEN)✓ Built $(BUILD_DIR)/$(APP_NAME).app$(NC)"

install: release ## Build and install to /Applications
	@echo "$(BLUE)Installing to $(INSTALL_DIR)...$(NC)"
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@cp -r $(BUILD_DIR)/$(APP_NAME).app $(INSTALL_DIR)/
	@echo "$(GREEN)✓ Installed to $(INSTALL_DIR)/$(APP_NAME).app$(NC)"
	@echo ""
	@echo "$(YELLOW)To start at login:$(NC)"
	@echo "  System Settings → General → Login Items → Add $(APP_NAME)"

uninstall: ## Remove from /Applications
	@echo "$(BLUE)Uninstalling...$(NC)"
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "$(GREEN)✓ Uninstalled$(NC)"

run: build ## Build and run debug version
	@echo "$(BLUE)Running...$(NC)"
	swift run $(APP_NAME)

test: ## Run tests
	swift test

clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning...$(NC)"
	swift package clean
	rm -rf $(BUILD_DIR)
	rm -rf .build
	@echo "$(GREEN)✓ Cleaned$(NC)"

# Tool-specific targets (add more as you create tools)
franco: release ## Build FrancoTranslator specifically
	@echo "$(GREEN)✓ FrancoTranslator ready at $(BUILD_DIR)/$(APP_NAME).app$(NC)"

# Release helpers
zip: release ## Create zip for GitHub release
	@echo "$(BLUE)Creating zip...$(NC)"
	@cd $(BUILD_DIR) && zip -r $(APP_NAME)-$(VERSION).zip $(APP_NAME).app
	@echo "$(GREEN)✓ Created $(BUILD_DIR)/$(APP_NAME)-$(VERSION).zip$(NC)"

dmg: release ## Create DMG for distribution
	@echo "$(BLUE)Creating DMG...$(NC)"
	@hdiutil create -volname "$(APP_NAME)" -srcfolder $(BUILD_DIR)/$(APP_NAME).app -ov -format UDZO $(BUILD_DIR)/$(APP_NAME)-$(VERSION).dmg
	@echo "$(GREEN)✓ Created $(BUILD_DIR)/$(APP_NAME)-$(VERSION).dmg$(NC)"
