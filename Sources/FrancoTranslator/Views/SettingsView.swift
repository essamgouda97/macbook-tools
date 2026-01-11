import SwiftUI
import MacToolsCore
import Carbon.HIToolbox

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showingKey: Bool = false
    @State private var saveStatus: SaveStatus = .idle
    @State private var hasExistingKey: Bool = false
    @State private var currentHotkey: Hotkey = HotkeyStorage.shared.hotkey
    @State private var isRecording: Bool = false

    enum SaveStatus {
        case idle, saving, saved, error(String)
    }

    var body: some View {
        Form {
            // Hotkey Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Keyboard Shortcut")
                        .font(.headline)

                    HStack {
                        HotkeyRecorderView(
                            hotkey: $currentHotkey,
                            isRecording: $isRecording
                        )

                        if currentHotkey != .defaultHotkey {
                            Button("Reset") {
                                HotkeyStorage.shared.reset()
                                currentHotkey = .defaultHotkey
                                NotificationCenter.default.post(name: .hotkeyChanged, object: nil)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Text("Click the box and press your desired shortcut")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // API Key Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("OpenAI API Key")
                        .font(.headline)

                    HStack {
                        if showingKey {
                            TextField("sk-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button(action: { showingKey.toggle() }) {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }

                    if hasExistingKey && apiKey.isEmpty {
                        Text("Using key from Keychain (or OPENAI_API_KEY env var)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Button("Save") {
                            saveAPIKey()
                        }
                        .disabled(apiKey.isEmpty)

                        if hasExistingKey {
                            Button("Delete", role: .destructive) {
                                deleteAPIKey()
                            }
                        }

                        Spacer()

                        switch saveStatus {
                        case .idle:
                            EmptyView()
                        case .saving:
                            ProgressView().scaleEffect(0.7)
                        case .saved:
                            Label("Saved", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .error(let msg):
                            Label(msg, systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                    }

                    Link("Get API key from OpenAI →",
                         destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
                }
            }

            // Accessibility Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accessibility")
                        .font(.headline)

                    HStack {
                        if AccessibilityManager.hasPermission {
                            Label("Permission granted", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Permission required", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Button("Grant") {
                                AccessibilityManager.openAccessibilitySettings()
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
        .onAppear {
            loadExistingKey()
        }
    }

    private func loadExistingKey() {
        hasExistingKey = KeychainManager.shared.hasOpenAIKey
    }

    private func saveAPIKey() {
        saveStatus = .saving
        do {
            try KeychainManager.shared.saveOpenAIKey(apiKey)
            saveStatus = .saved
            hasExistingKey = true
            apiKey = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if case .saved = saveStatus { saveStatus = .idle }
            }
        } catch {
            saveStatus = .error("Failed to save")
        }
    }

    private func deleteAPIKey() {
        do {
            try KeychainManager.shared.deleteOpenAIKey()
            hasExistingKey = false
            apiKey = ""
            saveStatus = .idle
        } catch {
            saveStatus = .error("Failed to delete")
        }
    }
}

// MARK: - Hotkey Recorder

struct HotkeyRecorderView: View {
    @Binding var hotkey: Hotkey
    @Binding var isRecording: Bool

    var body: some View {
        Button(action: { isRecording = true }) {
            Text(isRecording ? "Press shortcut..." : hotkey.displayString)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .frame(minWidth: 120)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .background(
            HotkeyRecorderHelper(isRecording: $isRecording, onRecord: { newHotkey in
                hotkey = newHotkey
                HotkeyStorage.shared.hotkey = newHotkey
                NotificationCenter.default.post(name: .hotkeyChanged, object: nil)
            })
        )
    }
}

struct HotkeyRecorderHelper: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onRecord: (Hotkey) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = RecorderView()
        view.onRecord = onRecord
        view.onStopRecording = { isRecording = false }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? RecorderView {
            if isRecording {
                view.window?.makeFirstResponder(view)
            }
        }
    }

    class RecorderView: NSView {
        var onRecord: ((Hotkey) -> Void)?
        var onStopRecording: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            // Convert NSEvent modifiers to Carbon modifiers
            var carbonMods: UInt32 = 0
            if event.modifierFlags.contains(.control) { carbonMods |= UInt32(controlKey) }
            if event.modifierFlags.contains(.option) { carbonMods |= UInt32(optionKey) }
            if event.modifierFlags.contains(.shift) { carbonMods |= UInt32(shiftKey) }
            if event.modifierFlags.contains(.command) { carbonMods |= UInt32(cmdKey) }

            // Require at least one modifier
            guard carbonMods != 0 else { return }

            let hotkey = Hotkey(keyCode: UInt32(event.keyCode), modifiers: carbonMods)
            onRecord?(hotkey)
            onStopRecording?()
        }

        override func resignFirstResponder() -> Bool {
            onStopRecording?()
            return super.resignFirstResponder()
        }
    }
}

extension Notification.Name {
    static let hotkeyChanged = Notification.Name("hotkeyChanged")
}
