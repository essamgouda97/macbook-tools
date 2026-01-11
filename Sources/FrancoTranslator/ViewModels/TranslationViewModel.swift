import Foundation
import SwiftUI
import AppKit

@MainActor
final class TranslationViewModel: ObservableObject {
    @Published var lastTranslation: String?
    @Published var isLoading = false
    @Published var error: String?
    @Published var justCopied = false

    private let translationService: TranslationService

    init(translationService: TranslationService = TranslationService()) {
        self.translationService = translationService
    }

    func translate(text: String) async {
        isLoading = true
        error = nil
        lastTranslation = nil
        justCopied = false

        do {
            let translation = try await translationService.translateFrancoToArabic(text: text)
            lastTranslation = translation

            // Auto-copy to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(translation, forType: .string)
            showCopied()

        } catch let err as TranslationError {
            error = err.userMessage
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func showCopied() {
        justCopied = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
            justCopied = false
        }
    }

    func reset() {
        lastTranslation = nil
        error = nil
        justCopied = false
    }
}
