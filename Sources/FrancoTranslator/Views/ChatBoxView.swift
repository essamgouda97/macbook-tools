import SwiftUI
import AppKit

struct ChatBoxView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Franco → Arabic")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { NSApp.keyWindow?.close() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }

            // Input field
            TextField("Type Franco...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($isInputFocused)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .onSubmit {
                    translate()
                }

            // Output area
            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Translating...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } else if let output = viewModel.lastTranslation {
                VStack(alignment: .trailing, spacing: 8) {
                    // Arabic output - RTL, full width, scrollable if needed
                    ScrollView {
                        Text(output)
                            .font(.system(size: 20))
                            .multilineTextAlignment(.trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .trailing)
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
            Text("⏎ translate • ⎋ close • ⌘+dbl-click")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(14)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .onAppear {
            isInputFocused = true
            viewModel.reset()
        }
    }

    private func translate() {
        guard !inputText.isEmpty, !viewModel.isLoading else { return }
        Task {
            await viewModel.translate(text: inputText)
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        viewModel.showCopied()
    }
}
