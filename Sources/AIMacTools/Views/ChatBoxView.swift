import SwiftUI
import AppKit

struct ChatBoxView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    var onPasteAndReturn: (() -> Void)?
    var onEscape: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with tool selector
            HStack {
                // Tool picker
                Picker("", selection: $viewModel.selectedTool) {
                    ForEach(Array(Tool.allTools.enumerated()), id: \.element.id) { index, tool in
                        Label(tool.name, systemImage: tool.icon)
                            .tag(tool)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()

                Spacer()

                // Tool shortcuts hint
                Text("⌘1/2/3")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))

                Button(action: { NSApp.keyWindow?.close() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
            }

            // Input field with dynamic placeholder
            TextField(viewModel.selectedTool.placeholder, text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($isInputFocused)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .onSubmit {
                    process()
                }

            // Output area
            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Processing...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } else if let output = viewModel.lastOutput {
                VStack(alignment: .trailing, spacing: 8) {
                    ScrollView {
                        Text(output)
                            .font(.system(size: viewModel.selectedTool.id == "franco" ? 20 : 14, design: viewModel.selectedTool.id == "terminal" ? .monospaced : .default))
                            .multilineTextAlignment(viewModel.selectedTool.id == "franco" ? .trailing : .leading)
                            .environment(\.layoutDirection, viewModel.selectedTool.id == "franco" ? .rightToLeft : .leftToRight)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: viewModel.selectedTool.id == "franco" ? .trailing : .leading)
                    }
                    .frame(maxHeight: 150)

                    HStack(spacing: 6) {
                        if viewModel.justCopied {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green)
                            Text("Copied!")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }

                        Spacer()

                        Button(action: { copyToClipboard(output) }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Copy again")
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            } else if let error = viewModel.error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }

            Spacer(minLength: 0)

            // Hint
            Text("⏎ run • ⎋ close • ⌘1/2/3 switch")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(14)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .background(KeyboardShortcutHandler(
            onToolSelect: { index in
                if index < Tool.allTools.count {
                    viewModel.selectTool(Tool.allTools[index])
                }
            },
            onNextTool: {
                cycleToNextTool()
            },
            onEscape: { [onEscape] in
                if let onEscape = onEscape {
                    onEscape()
                } else {
                    NSApp.keyWindow?.close()
                }
            },
            onPaste: {
                onPasteAndReturn?()
            }
        ))
        .onAppear {
            inputText = ""
            viewModel.reset()
            // Multiple focus attempts
            for delay in [0.05, 0.1, 0.2, 0.3] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    isInputFocused = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("FocusTextField"))) { _ in
            isInputFocused = true
        }
        .onExitCommand {
            if let onEscape = onEscape {
                onEscape()
            } else {
                NSApp.keyWindow?.close()
            }
        }
    }

    private func process() {
        guard !inputText.isEmpty, !viewModel.isLoading else { return }
        Task {
            await viewModel.process(input: inputText)
        }
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
            // ⌘V for paste and return to previous app
            if event.modifierFlags.contains(.command),
               event.charactersIgnoringModifiers == "v" {
                onPaste?()
                return true
            }

            // ⌘1, ⌘2, ⌘3 for tool selection
            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "1":
                    onToolSelect?(0)
                    return true
                case "2":
                    onToolSelect?(1)
                    return true
                case "3":
                    onToolSelect?(2)
                    return true
                default:
                    break
                }
            }

            // Tab for cycling (without modifiers)
            if event.keyCode == 48 && !event.modifierFlags.contains(.command) {
                onNextTool?()
                return true
            }

            // Escape
            if event.keyCode == 53 {
                onEscape?()
                return true
            }

            return super.performKeyEquivalent(with: event)
        }
    }
}
