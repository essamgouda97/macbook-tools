import Foundation
import SwiftUI
import AppKit

@MainActor
final class TranslationViewModel: ObservableObject {
    @Published var selectedTool: Tool {
        didSet {
            ToolStorage.shared.selectedTool = selectedTool
        }
    }
    @Published var lastOutput: String?
    @Published var isLoading = false
    @Published var error: String?
    @Published var justCopied = false

    private let llmService: LLMService

    init(llmService: LLMService = LLMService()) {
        self.llmService = llmService
        self.selectedTool = ToolStorage.shared.selectedTool
    }

    func process(input: String) async {
        isLoading = true
        error = nil
        lastOutput = nil
        justCopied = false

        do {
            let output = try await llmService.process(input: input, tool: selectedTool)
            lastOutput = output

            // Auto-copy to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(output, forType: .string)
            showCopied()

        } catch let err as LLMError {
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
        lastOutput = nil
        error = nil
        justCopied = false
    }

    func selectTool(_ tool: Tool) {
        selectedTool = tool
        reset()
    }
}
