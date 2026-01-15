import Foundation

/// Represents a tool in the multi-tool interface
public struct Tool: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let icon: String
    public let placeholder: String
    public let systemPrompt: String
    public let contextLoader: (() async -> String?)?

    public init(
        id: String,
        name: String,
        icon: String,
        placeholder: String,
        systemPrompt: String,
        contextLoader: (() async -> String?)? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.placeholder = placeholder
        self.systemPrompt = systemPrompt
        self.contextLoader = contextLoader
    }

    // Hashable conformance (ignore contextLoader)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Tool, rhs: Tool) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tool Definitions

extension Tool {
    /// Franco → Arabic translator (⌘1)
    public static let francoTranslator = Tool(
        id: "franco",
        name: "Franco → Arabic",
        icon: "character.bubble",
        placeholder: "Type Franco Arabic...",
        systemPrompt: """
        You are a translator that converts Egyptian Franco-Arabic (Arabizi) to Egyptian Arabic.

        Franco-Arabic uses Latin letters and numbers to represent Arabic sounds:
        - 2 = ء (hamza/glottal stop)
        - 3 = ع (ain)
        - 5 or kh = خ (kha)
        - 7 = ح (ha - emphatic h)
        - 8 or gh = غ (ghain)
        - 9 or q = ق (qaf)
        - sh = ش
        - ch = تش

        Common Egyptian Franco examples:
        - "ezayak" → "إزيك"
        - "ana 3ayez akol" → "أنا عايز آكل"
        - "el7amdulellah" → "الحمد لله"
        - "ma3lesh" → "معلش"
        - "7abibi" → "حبيبي"

        Rules:
        1. Respond ONLY with the Arabic translation
        2. Use Egyptian Arabic dialect, not Modern Standard Arabic
        3. Preserve the meaning and tone
        4. Do not add explanations or notes
        """
    )

    /// Terminal command helper (⌘2)
    public static let terminalHelper = Tool(
        id: "terminal",
        name: "Terminal",
        icon: "terminal",
        placeholder: "Describe what you want to do...",
        systemPrompt: """
        Convert natural language to shell commands for macOS/zsh.

        User's shell configuration is provided below for context (aliases, functions, environment).
        Use their defined aliases and functions when appropriate.

        Rules:
        1. Respond ONLY with the command, no explanation
        2. ALWAYS output a SINGLE one-liner - chain multiple operations with && (dependent) or ; (independent)
           Example: mkdir project && cd project && git init
        3. Prefer simple, safe commands
        4. Use the user's aliases when they match the intent
        5. Do not add backticks, code blocks, or formatting
        """,
        contextLoader: {
            let zshrcPath = NSString("~/.zshrc").expandingTildeInPath
            return try? String(contentsOfFile: zshrcPath, encoding: .utf8)
        }
    )

    /// Spelling & grammar fixer (⌘3)
    public static let spellFixer = Tool(
        id: "spell",
        name: "Fix Spelling",
        icon: "textformat.abc",
        placeholder: "Paste text to fix...",
        systemPrompt: """
        Fix spelling and grammar errors in the text.

        Rules:
        1. Keep the original meaning, tone, and style
        2. Don't rewrite or improve the text - only fix errors
        3. Preserve formatting (newlines, paragraphs, etc.)
        4. Respond ONLY with the corrected text
        5. If the text has no errors, return it unchanged
        6. Do not add explanations or notes
        """
    )

    /// All available tools (order matters for ⌘1/2/3)
    public static let allTools: [Tool] = [
        .francoTranslator,  // ⌘1
        .terminalHelper,    // ⌘2
        .spellFixer         // ⌘3
    ]

    /// Find tool by ID
    public static func tool(forID id: String) -> Tool? {
        allTools.first { $0.id == id }
    }
}

// MARK: - Tool Storage

public final class ToolStorage {
    public static let shared = ToolStorage()
    private let key = "selected_tool_id"

    public var selectedTool: Tool {
        get {
            guard let id = UserDefaults.standard.string(forKey: key),
                  let tool = Tool.tool(forID: id) else {
                return .francoTranslator
            }
            return tool
        }
        set {
            UserDefaults.standard.set(newValue.id, forKey: key)
        }
    }
}
