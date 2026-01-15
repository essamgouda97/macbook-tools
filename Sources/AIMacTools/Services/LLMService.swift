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

    /// Process input using the specified tool
    func process(input: String, tool: Tool) async throws -> String {
        // Try env var first, then Keychain
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            ?? KeychainManager.shared.getOpenAIKey()

        guard let apiKey = apiKey, !apiKey.isEmpty else {
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
        var userMessage = input
        if let clipboardText = getClipboardText(), !clipboardText.isEmpty, clipboardText != input {
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
