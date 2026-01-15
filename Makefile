.PHONY: all build release install uninstall clean run test help dev stop restore status tag publish github-release

# Configuration
APP_NAME = AIMacTools
BUNDLE_ID = com.aimactools.app
VERSION = 1.0.2
BUILD_DIR = build
INSTALL_DIR = /Applications

# Colors
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m

help: ## Show this help
	@echo "AI Mac Tools - Available commands:"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  $(BLUE)make dev$(NC)         Test code changes (runs from source)"
	@echo "  $(BLUE)make stop$(NC)        Stop the running app"
	@echo "  $(BLUE)make restore$(NC)     Restart installed app"
	@echo "  $(BLUE)make reinstall$(NC)   Rebuild + install + restart"
	@echo ""
	@echo "$(YELLOW)Release:$(NC)"
	@echo "  $(BLUE)make github-release v=X.Y.Z$(NC)  Create GitHub release (one command!)"
	@echo "  $(BLUE)make publish$(NC)                 Build zip only"
	@echo ""
	@echo "$(YELLOW)All commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Workflows:$(NC)"
	@echo "  Development:  make dev → test → make restore"
	@echo "  Ship changes: make reinstall"
	@echo "  New release:  make github-release v=1.2.0  (does everything!)"
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
	@cp Resources/Info.plist $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
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
	@echo "$(BLUE)Stopping ALL instances...$(NC)"
	@-pkill -9 -x $(APP_NAME) 2>/dev/null || true
	@-pkill -9 -f "$(INSTALL_DIR)/$(APP_NAME).app" 2>/dev/null || true
	@-pkill -9 -f ".build.*$(APP_NAME)" 2>/dev/null || true
	@sleep 1
	@echo "$(BLUE)Building and running from source...$(NC)"
	@swift build
	@echo "$(GREEN)✓ Starting dev version...$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop, then 'make restore' to return to installed app$(NC)"
	@echo ""
	@-pkill -9 -x $(APP_NAME) 2>/dev/null || true
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

# =============================================================================
# Release Workflow
# =============================================================================

tag: ## Create and push a git tag (usage: make tag v=1.0.0)
	@if [ -z "$(v)" ]; then \
		echo "$(RED)Error: Version required. Usage: make tag v=1.0.0$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Creating tag $(v)...$(NC)"
	@git tag -a $(v) -m "Release $(v)"
	@git push origin $(v)
	@echo "$(GREEN)✓ Tag $(v) created and pushed$(NC)"

publish: zip ## Create release zip and show next steps
	@echo ""
	@echo "$(GREEN)✓ Release package ready!$(NC)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Create tag:    make tag v=$(VERSION)"
	@echo "  2. Go to:         https://github.com/egouda/macbook_tools/releases/new"
	@echo "  3. Select tag:    $(VERSION)"
	@echo "  4. Upload:        $(BUILD_DIR)/$(APP_NAME)-$(VERSION).zip"
	@echo "  5. Add release notes and publish"
	@echo ""

github-release: ## Full release: bump version, build, tag, push, create GitHub release
	@if [ -z "$(v)" ]; then \
		echo "$(RED)Error: Version required. Usage: make github-release v=1.2.0$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)═══════════════════════════════════════════$(NC)"
	@echo "$(BLUE)  Creating release v$(v)$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(BLUE)[1/6] Updating version to $(v)...$(NC)"
	@sed -i '' 's/^VERSION = .*/VERSION = $(v)/' Makefile
	@plutil -replace CFBundleVersion -string "$(v)" Resources/Info.plist
	@plutil -replace CFBundleShortVersionString -string "$(v)" Resources/Info.plist
	@echo "$(GREEN)✓ Version updated in Makefile and Info.plist$(NC)"
	@echo ""
	@echo "$(BLUE)[2/6] Building release...$(NC)"
	@swift build -c release
	@mkdir -p $(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS
	@mkdir -p $(BUILD_DIR)/$(APP_NAME).app/Contents/Resources
	@cp .build/release/$(APP_NAME) $(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS/
	@cp Resources/Info.plist $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo -n 'APPL????' > $(BUILD_DIR)/$(APP_NAME).app/Contents/PkgInfo
	@echo "$(GREEN)✓ Built $(APP_NAME).app$(NC)"
	@echo ""
	@echo "$(BLUE)[3/6] Creating zip...$(NC)"
	@cd $(BUILD_DIR) && zip -r $(APP_NAME)-$(v).zip $(APP_NAME).app
	@echo "$(GREEN)✓ Created $(APP_NAME)-$(v).zip$(NC)"
	@echo ""
	@echo "$(BLUE)[4/6] Committing version bump...$(NC)"
	@git add Makefile Resources/Info.plist
	@git commit -m "Bump version to $(v)" 2>/dev/null || echo "$(YELLOW)Nothing to commit$(NC)"
	@git push origin main 2>/dev/null || true
	@echo "$(GREEN)✓ Committed and pushed$(NC)"
	@echo ""
	@echo "$(BLUE)[5/6] Creating git tag v$(v)...$(NC)"
	@git tag -a v$(v) -m "Release $(v)" 2>/dev/null || echo "$(YELLOW)Tag already exists$(NC)"
	@git push origin v$(v) 2>/dev/null || echo "$(YELLOW)Tag already pushed$(NC)"
	@echo "$(GREEN)✓ Tag created$(NC)"
	@echo ""
	@echo "$(BLUE)[6/6] Creating GitHub release...$(NC)"
	@gh release create v$(v) \
		$(BUILD_DIR)/$(APP_NAME)-$(v).zip \
		--title "$(APP_NAME) v$(v)" \
		--notes-file CHANGELOG.md \
		--latest
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════════$(NC)"
	@echo "$(GREEN)  ✓ Release v$(v) published!$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════$(NC)"
	@echo ""
	@echo "View at: https://github.com/essamgouda97/macbook-tools/releases/tag/v$(v)"
