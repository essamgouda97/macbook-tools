.PHONY: all build release install uninstall clean run test help dev stop restore status

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
RED = \033[0;31m
NC = \033[0m

help: ## Show this help
	@echo "MacBook Tools - Available commands:"
	@echo ""
	@echo "$(YELLOW)Development workflow:$(NC)"
	@echo "  $(BLUE)make dev$(NC)         Test code changes (stops installed app, runs from source)"
	@echo "  $(BLUE)make stop$(NC)        Stop the running app"
	@echo "  $(BLUE)make restore$(NC)     Stop dev version, restart installed app"
	@echo "  $(BLUE)make status$(NC)      Show which version is running"
	@echo ""
	@echo "$(YELLOW)All commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Typical workflows:$(NC)"
	@echo "  Development:  make dev → test → make restore"
	@echo "  Ship changes: make dev → test → make install → make restore"
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

# =============================================================================
# Development Workflow
# =============================================================================

dev: ## Test changes: stop app, build, run from source
	@echo "$(BLUE)Stopping any running instance...$(NC)"
	@-pkill -x $(APP_NAME) 2>/dev/null || true
	@sleep 0.5
	@echo "$(BLUE)Building and running from source...$(NC)"
	@swift build
	@echo "$(GREEN)✓ Starting dev version...$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop, then 'make restore' to return to installed app$(NC)"
	@echo ""
	@swift run $(APP_NAME)

stop: ## Stop the running app (any version)
	@echo "$(BLUE)Stopping $(APP_NAME)...$(NC)"
	@-pkill -x $(APP_NAME) 2>/dev/null && echo "$(GREEN)✓ Stopped$(NC)" || echo "$(YELLOW)Not running$(NC)"

restore: ## Stop dev version and restart installed app
	@echo "$(BLUE)Restoring installed app...$(NC)"
	@-pkill -x $(APP_NAME) 2>/dev/null || true
	@sleep 0.5
	@if [ -d "$(INSTALL_DIR)/$(APP_NAME).app" ]; then \
		open "$(INSTALL_DIR)/$(APP_NAME).app"; \
		echo "$(GREEN)✓ Restored $(INSTALL_DIR)/$(APP_NAME).app$(NC)"; \
	else \
		echo "$(RED)✗ No installed app found. Run 'make install' first.$(NC)"; \
	fi

status: ## Show which version is running
	@echo "$(BLUE)Checking status...$(NC)"
	@if pgrep -x $(APP_NAME) > /dev/null; then \
		PID=$$(pgrep -x $(APP_NAME)); \
		PATH_INFO=$$(ps -p $$PID -o comm= 2>/dev/null); \
		if echo "$$PATH_INFO" | grep -q "\.build"; then \
			echo "$(YELLOW)● Running: dev version (from source)$(NC)"; \
		elif echo "$$PATH_INFO" | grep -q "Applications"; then \
			echo "$(GREEN)● Running: installed app (/Applications)$(NC)"; \
		else \
			echo "$(GREEN)● Running: PID $$PID$(NC)"; \
		fi; \
	else \
		echo "$(RED)○ Not running$(NC)"; \
	fi
	@echo ""
	@if [ -d "$(INSTALL_DIR)/$(APP_NAME).app" ]; then \
		echo "Installed: $(INSTALL_DIR)/$(APP_NAME).app"; \
	else \
		echo "Installed: $(RED)not installed$(NC)"; \
	fi

reinstall: stop install restore ## Stop, rebuild, install, and restart
