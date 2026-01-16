import Foundation
import OpenAI
import MacToolsCore
import AppKit

enum LLMError: LocalizedError {
    case noAPIKey
    case noResponse
    case networkError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured"
        case .noResponse:
            return "No response received"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }

    var userMessage: String {
        switch self {
        case .noAPIKey:
            return "Please set your OpenAI API key in Settings (click menu bar icon → Settings)"
        case .noResponse:
            return "No response received. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

final class LLMService {

    /// Get current clipboard text (truncated if too long)
    private func getClipboardText() -> String? {
        guard let text = NSPasteboard.general.string(forType: .string) else { return nil }
        // Truncate to ~500 chars to avoid bloating the prompt
        if text.count > 500 {
            return String(text.prefix(500)) + "..."
        }
        return text
    }

    /// Read OPENAI_API_KEY from ~/.zshrc (GUI apps don't inherit shell env vars)
    private func getAPIKeyFromZshrc() -> String? {
        let zshrcPath = NSString("~/.zshrc").expandingTildeInPath
        guard let content = try? String(contentsOfFile: zshrcPath, encoding: .utf8) else { return nil }

        // Look for: export OPENAI_API_KEY="..." or export OPENAI_API_KEY='...' or export OPENAI_API_KEY=...
        let patterns = [
            "export\\s+OPENAI_API_KEY\\s*=\\s*[\"']([^\"']+)[\"']",  // quoted
            "export\\s+OPENAI_API_KEY\\s*=\\s*([^\\s#]+)"            // unquoted
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
               let range = Range(match.range(at: 1), in: content) {
                return String(content[range])
            }
        }
        return nil
    }

    /// Process input using the specified tool
    func process(input: String, tool: Tool) async throws -> String {
        // Try: 1) env var, 2) Keychain, 3) ~/.zshrc
        // Use helper to skip empty strings in the chain
        func nonEmpty(_ s: String?) -> String? {
            guard let s = s, !s.isEmpty else { return nil }
            return s
        }

        guard let apiKey = nonEmpty(ProcessInfo.processInfo.environment["OPENAI_API_KEY"])
                ?? nonEmpty(KeychainManager.shared.getOpenAIKey())
                ?? nonEmpty(getAPIKeyFromZshrc()) else {
            throw LLMError.noAPIKey
        }

        let openAI = OpenAI(apiToken: apiKey)

        // Build system prompt with optional context
        var systemPrompt = tool.systemPrompt

        // Load additional context if tool has a context loader
        if let contextLoader = tool.contextLoader {
            if let context = await contextLoader() {
                systemPrompt += "\n\n--- User's Shell Config ---\n\(context)"
            }
        }

        // Build user message with optional clipboard context
        // Franco doesn't need clipboard context (it's either the input already, or should be ignored)
        var userMessage = input
        if tool.id != "franco",
           let clipboardText = getClipboardText(),
           !clipboardText.isEmpty,
           clipboardText != input {
            userMessage = """
            \(input)

            ---
            [Clipboard content - may or may not be relevant to the task above]:
            \(clipboardText)
            """
        }

        let messages: [ChatQuery.ChatCompletionMessageParam] = [
            .init(role: .system, content: systemPrompt)!,
            .init(role: .user, content: userMessage)!
        ]

        let query = ChatQuery(
            messages: messages,
            model: .gpt4_turbo,
            temperature: 0.3
        )

        do {
            let result = try await openAI.chats(query: query)

            guard let choice = result.choices.first,
                  let response = choice.message.content else {
                throw LLMError.noResponse
            }

            return response.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } catch let error as LLMError {
            throw error
        } catch {
            throw LLMError.networkError(error)
        }
    }
}
