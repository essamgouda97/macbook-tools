import SwiftUI
import AppKit

struct ChatBoxView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    var onPasteAndReturn: (() -> Void)?
    var onEscape: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Minimal header - just tool pill
            HStack(spacing: 6) {
                Image(systemName: viewModel.selectedTool.icon)
                    .font(.system(size: 11, weight: .medium))
                Text(viewModel.selectedTool.name)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
            .foregroundColor(.accentColor)
            .onTapGesture { cycleToNextTool() }

            // Input field
            TextField(viewModel.selectedTool.placeholder, text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isInputFocused)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .onSubmit { process() }

            // Output area - compact
            if viewModel.isLoading {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            } else if let output = viewModel.lastOutput {
                outputView(output)
            } else if let error = viewModel.error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        )
        .background(KeyboardShortcutHandler(
            onToolSelect: { index in
                if index < Tool.allTools.count {
                    viewModel.selectTool(Tool.allTools[index])
                }
            },
            onNextTool: { cycleToNextTool() },
            onEscape: { onEscape?() ?? NSApp.keyWindow?.close() },
            onPaste: { onPasteAndReturn?() }
        ))
        .onAppear {
            inputText = ""
            viewModel.reset()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isInputFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("FocusTextField"))) { _ in
            isInputFocused = true
        }
    }

    @ViewBuilder
    private func outputView(_ output: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            ScrollView {
                Text(output)
                    .font(.system(size: viewModel.selectedTool.id == "franco" ? 18 : 13,
                                  design: viewModel.selectedTool.id == "terminal" ? .monospaced : .default))
                    .multilineTextAlignment(viewModel.selectedTool.id == "franco" ? .trailing : .leading)
                    .environment(\.layoutDirection, viewModel.selectedTool.id == "franco" ? .rightToLeft : .leftToRight)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: viewModel.selectedTool.id == "franco" ? .trailing : .leading)
            }
            .frame(maxHeight: 120)

            HStack(spacing: 4) {
                if viewModel.justCopied {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
                Spacer()
                Button(action: { copyToClipboard(output) }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func process() {
        guard !viewModel.isLoading else { return }

        let toolId = viewModel.selectedTool.id
        let clipboard = NSPasteboard.general.string(forType: .string) ?? ""

        // Determine input based on tool type
        let finalInput: String
        switch toolId {
        case "franco":
            // Empty → use clipboard; typed → use typed text only
            finalInput = inputText.isEmpty ? clipboard : inputText
        case "rewrite":
            // Empty → fix spelling instruction; typed → custom instruction
            // (clipboard is added as context in LLMService)
            finalInput = inputText.isEmpty ? "fix spelling and grammar" : inputText
        default:
            // Other tools require typed input
            if inputText.isEmpty { return }
            finalInput = inputText
        }

        guard !finalInput.isEmpty else { return }
        Task { await viewModel.process(input: finalInput) }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        viewModel.showCopied()
    }

    private func cycleToNextTool() {
        guard let currentIndex = Tool.allTools.firstIndex(where: { $0.id == viewModel.selectedTool.id }) else { return }
        let nextIndex = (currentIndex + 1) % Tool.allTools.count
        viewModel.selectTool(Tool.allTools[nextIndex])
    }
}

// MARK: - Keyboard Shortcut Handler

struct KeyboardShortcutHandler: NSViewRepresentable {
    let onToolSelect: (Int) -> Void
    let onNextTool: () -> Void
    let onEscape: () -> Void
    let onPaste: () -> Void

    func makeNSView(context: Context) -> KeyEventView {
        let view = KeyEventView()
        view.onToolSelect = onToolSelect
        view.onNextTool = onNextTool
        view.onEscape = onEscape
        view.onPaste = onPaste
        return view
    }

    func updateNSView(_ nsView: KeyEventView, context: Context) {
        nsView.onToolSelect = onToolSelect
        nsView.onNextTool = onNextTool
        nsView.onEscape = onEscape
        nsView.onPaste = onPaste
    }

    class KeyEventView: NSView {
        var onToolSelect: ((Int) -> Void)?
        var onNextTool: (() -> Void)?
        var onEscape: (() -> Void)?
        var onPaste: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "v": onPaste?(); return true
                case "1": onToolSelect?(0); return true
                case "2": onToolSelect?(1); return true
                case "3": onToolSelect?(2); return true
                default: break
                }
            }
            if event.keyCode == 48 && !event.modifierFlags.contains(.command) {
                onNextTool?()
                return true
            }
            if event.keyCode == 53 {
                onEscape?()
                return true
            }
            return super.performKeyEquivalent(with: event)
        }
    }
}
