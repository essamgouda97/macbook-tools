import SwiftUI
import AppKit

struct ChatBoxView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with tool selector
            HStack {
                // Tool picker
                Picker("", selection: $viewModel.selectedTool) {
                    ForEach(Tool.allTools) { tool in
                        Label(tool.name, systemImage: tool.icon)
                            .tag(tool)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()

                Spacer()

                // Click hint
                Text("⌘+\(viewModel.selectedTool.clickCount)×click")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))

                Button(action: { NSApp.keyWindow?.close() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
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
                    // Output - RTL for Arabic, LTR for others
                    ScrollView {
                        Text(output)
                            .font(.system(size: viewModel.selectedTool.id == "franco" ? 20 : 14, design: viewModel.selectedTool.id == "terminal" ? .monospaced : .default))
                            .multilineTextAlignment(viewModel.selectedTool.id == "franco" ? .trailing : .leading)
                            .environment(\.layoutDirection, viewModel.selectedTool.id == "franco" ? .rightToLeft : .leftToRight)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: viewModel.selectedTool.id == "franco" ? .trailing : .leading)
                    }
                    .frame(maxHeight: 150)

                    // Copy indicator
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
            Text("⏎ run • ⎋ close • ⌘+2/3/4×click")
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
        .onAppear {
            isInputFocused = true
            inputText = ""
            viewModel.reset()
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
}
