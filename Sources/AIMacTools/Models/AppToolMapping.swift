import Foundation

/// Maps an app (by bundle ID) to a preferred tool
struct AppToolMapping: Codable, Identifiable, Equatable {
    var id: String { bundleID }
    let bundleID: String      // e.g., "com.apple.Terminal"
    let appName: String       // e.g., "Terminal" (for display)
    var toolID: String        // e.g., "terminal"
}

/// Stores and retrieves app→tool mappings
final class AppToolMappingStorage {
    static let shared = AppToolMappingStorage()
    private let key = "app_tool_mappings"

    /// Default mappings (built-in)
    static let defaults: [AppToolMapping] = [
        // Terminals → Terminal tool
        AppToolMapping(bundleID: "com.apple.Terminal", appName: "Terminal", toolID: "terminal"),
        AppToolMapping(bundleID: "com.googlecode.iterm2", appName: "iTerm", toolID: "terminal"),
        AppToolMapping(bundleID: "dev.warp.Warp-Stable", appName: "Warp", toolID: "terminal"),
        AppToolMapping(bundleID: "io.alacritty", appName: "Alacritty", toolID: "terminal"),
        AppToolMapping(bundleID: "co.zeit.hyper", appName: "Hyper", toolID: "terminal"),

        // Code editors → Terminal tool
        AppToolMapping(bundleID: "com.microsoft.VSCode", appName: "VS Code", toolID: "terminal"),
        AppToolMapping(bundleID: "com.apple.dt.Xcode", appName: "Xcode", toolID: "terminal"),
        AppToolMapping(bundleID: "com.todesktop.230313mzl4w4u92", appName: "Cursor", toolID: "terminal"),
        AppToolMapping(bundleID: "com.sublimetext.4", appName: "Sublime Text", toolID: "terminal"),

        // Browsers → Spell tool
        AppToolMapping(bundleID: "com.apple.Safari", appName: "Safari", toolID: "spell"),
        AppToolMapping(bundleID: "com.google.Chrome", appName: "Chrome", toolID: "spell"),
        AppToolMapping(bundleID: "org.mozilla.firefox", appName: "Firefox", toolID: "spell"),
        AppToolMapping(bundleID: "company.thebrowser.Browser", appName: "Arc", toolID: "spell"),
        AppToolMapping(bundleID: "com.microsoft.edgemac", appName: "Edge", toolID: "spell"),
        AppToolMapping(bundleID: "com.brave.Browser", appName: "Brave", toolID: "spell"),

        // Writing apps → Spell tool
        AppToolMapping(bundleID: "com.apple.Notes", appName: "Notes", toolID: "spell"),
        AppToolMapping(bundleID: "com.apple.TextEdit", appName: "TextEdit", toolID: "spell"),
        AppToolMapping(bundleID: "com.apple.iWork.Pages", appName: "Pages", toolID: "spell"),
        AppToolMapping(bundleID: "com.microsoft.Word", appName: "Word", toolID: "spell"),
        AppToolMapping(bundleID: "notion.id", appName: "Notion", toolID: "spell"),
        AppToolMapping(bundleID: "md.obsidian", appName: "Obsidian", toolID: "spell"),

        // Chat apps → Spell tool
        AppToolMapping(bundleID: "com.tinyspeck.slackmacgap", appName: "Slack", toolID: "spell"),
        AppToolMapping(bundleID: "com.hnc.Discord", appName: "Discord", toolID: "spell"),
        AppToolMapping(bundleID: "com.apple.MobileSMS", appName: "Messages", toolID: "spell"),
        AppToolMapping(bundleID: "ru.keepcoder.Telegram", appName: "Telegram", toolID: "spell"),
        AppToolMapping(bundleID: "com.facebook.archon", appName: "Messenger", toolID: "spell"),

        // Email → Spell tool
        AppToolMapping(bundleID: "com.apple.mail", appName: "Mail", toolID: "spell"),
        AppToolMapping(bundleID: "com.google.Gmail", appName: "Gmail", toolID: "spell"),
    ]

    private init() {}

    /// Current mappings (user-customized or defaults)
    var mappings: [AppToolMapping] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode([AppToolMapping].self, from: data) else {
                return Self.defaults
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }

    /// Look up the preferred tool ID for a given app bundle ID
    func toolID(for bundleID: String) -> String? {
        mappings.first { $0.bundleID == bundleID }?.toolID
    }

    /// Add or update a mapping
    func setMapping(_ mapping: AppToolMapping) {
        var current = mappings
        if let index = current.firstIndex(where: { $0.bundleID == mapping.bundleID }) {
            current[index] = mapping
        } else {
            current.append(mapping)
        }
        mappings = current
    }

    /// Remove a mapping by bundle ID
    func removeMapping(bundleID: String) {
        var current = mappings
        current.removeAll { $0.bundleID == bundleID }
        mappings = current
    }

    /// Reset to default mappings
    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// Check if user has customized mappings
    var hasCustomMappings: Bool {
        UserDefaults.standard.data(forKey: key) != nil
    }
}
