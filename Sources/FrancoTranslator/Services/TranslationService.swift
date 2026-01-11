import Foundation
import OpenAI
import MacToolsCore

enum TranslationError: LocalizedError {
    case noAPIKey
    case noResponse
    case networkError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured"
        case .noResponse:
            return "No translation received"
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
            return "No translation received. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

final class TranslationService {
    private let systemPrompt = """
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
    - "ezayek" → "إزيك" (feminine)
    - "ana 3ayez akol" → "أنا عايز آكل"
    - "el7amdulellah" → "الحمد لله"
    - "ma3lesh" → "معلش"
    - "2ahwa" → "قهوة"
    - "shokran" → "شكراً"
    - "inshallah" → "إن شاء الله"
    - "mabrou" → "مبروك"
    - "7abibi" → "حبيبي"

    Rules:
    1. Respond ONLY with the Arabic translation
    2. Use Egyptian Arabic dialect, not Modern Standard Arabic
    3. Preserve the meaning and tone
    4. If unsure, provide the most likely Egyptian interpretation
    5. Do not add explanations or notes
    """

    func translateFrancoToArabic(text: String) async throws -> String {
        // Try env var first, then Keychain
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            ?? KeychainManager.shared.getOpenAIKey()

        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw TranslationError.noAPIKey
        }

        let openAI = OpenAI(apiToken: apiKey)

        let messages: [ChatQuery.ChatCompletionMessageParam] = [
            .init(role: .system, content: systemPrompt)!,
            .init(role: .user, content: text)!
        ]

        let query = ChatQuery(
            messages: messages,
            model: .gpt4_turbo,
            temperature: 0.3
        )

        do {
            let result = try await openAI.chats(query: query)

            guard let choice = result.choices.first,
                  let translation = choice.message.content else {
                throw TranslationError.noResponse
            }

            return translation.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.networkError(error)
        }
    }
}
