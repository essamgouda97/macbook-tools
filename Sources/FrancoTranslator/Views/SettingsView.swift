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

    // App Mappings
    @State private var mappings: [AppToolMapping] = []
    @State private var showingAddApp: Bool = false

    enum SaveStatus {
        case idle, saving, saved, error(String)
    }

    var body: some View {
        Form {
            // App Mappings Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("App Mappings")
                        .font(.headline)

                    Text("Auto-select tool based on source app")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Mappings list
                    if mappings.isEmpty {
                        Text("No mappings configured")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        VStack(spacing: 0) {
                            ForEach(mappings) { mapping in
                                AppMappingRow(
                                    mapping: mapping,
                                    onToolChange: { newToolID in
                                        updateMapping(mapping, toolID: newToolID)
                                    },
                                    onDelete: {
                                        deleteMapping(mapping)
                                    }
                                )
                                if mapping.id != mappings.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }

                    // Action buttons
                    HStack {
                        Button(action: { showingAddApp = true }) {
                            Label("Add App", systemImage: "plus")
                        }
                        .buttonStyle(.borderless)

                        Spacer()

                        if AppToolMappingStorage.shared.hasCustomMappings {
                            Button("Reset Defaults") {
                                resetMappings()
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }

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

            // Permissions Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissions")
                        .font(.headline)

                    HStack {
                        Image(systemName: AccessibilityManager.hasPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(AccessibilityManager.hasPermission ? .green : .red)
                        Text("Accessibility")
                        Spacer()
                        if !AccessibilityManager.hasPermission {
                            Button("Open Settings") {
                                AccessibilityManager.openAccessibilitySettings()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }

                    Text("Required for ⌘+tap detection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 560)
        .onAppear {
            loadExistingKey()
            loadMappings()
        }
        .sheet(isPresented: $showingAddApp) {
            AddAppSheet(onAdd: { mapping in
                addMapping(mapping)
            })
        }
    }

    // MARK: - Mappings

    private func loadMappings() {
        mappings = AppToolMappingStorage.shared.mappings
    }

    private func updateMapping(_ mapping: AppToolMapping, toolID: String) {
        var updated = mapping
        updated.toolID = toolID
        AppToolMappingStorage.shared.setMapping(updated)
        loadMappings()
    }

    private func deleteMapping(_ mapping: AppToolMapping) {
        AppToolMappingStorage.shared.removeMapping(bundleID: mapping.bundleID)
        loadMappings()
    }

    private func addMapping(_ mapping: AppToolMapping) {
        AppToolMappingStorage.shared.setMapping(mapping)
        loadMappings()
    }

    private func resetMappings() {
        AppToolMappingStorage.shared.reset()
        loadMappings()
    }

    // MARK: - API Key

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

// MARK: - App Mapping Row

struct AppMappingRow: View {
    let mapping: AppToolMapping
    let onToolChange: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(mapping.appName)
                .frame(width: 120, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("", selection: Binding(
                get: { mapping.toolID },
                set: { onToolChange($0) }
            )) {
                ForEach(Tool.allTools, id: \.id) { tool in
                    Text(tool.name).tag(tool.id)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 140)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
            .help("Remove mapping")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Add App Sheet

struct AddAppSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (AppToolMapping) -> Void

    @State private var runningApps: [NSRunningApplication] = []
    @State private var selectedApp: NSRunningApplication?
    @State private var selectedToolID: String = "franco"

    var body: some View {
        VStack(spacing: 16) {
            Text("Add App Mapping")
                .font(.headline)

            // App picker from running apps
            VStack(alignment: .leading, spacing: 8) {
                Text("Select an app:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("", selection: $selectedApp) {
                    Text("Choose app...").tag(nil as NSRunningApplication?)
                    ForEach(runningApps, id: \.processIdentifier) { app in
                        Text(app.localizedName ?? "Unknown")
                            .tag(app as NSRunningApplication?)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            // Tool picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Default tool:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("", selection: $selectedToolID) {
                    ForEach(Tool.allTools, id: \.id) { tool in
                        Label(tool.name, systemImage: tool.icon).tag(tool.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            Spacer()

            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    if let app = selectedApp,
                       let bundleID = app.bundleIdentifier {
                        let mapping = AppToolMapping(
                            bundleID: bundleID,
                            appName: app.localizedName ?? "Unknown",
                            toolID: selectedToolID
                        )
                        onAdd(mapping)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedApp == nil)
            }
        }
        .padding(20)
        .frame(width: 300, height: 220)
        .onAppear {
            loadRunningApps()
        }
    }

    private func loadRunningApps() {
        let existingBundleIDs = Set(AppToolMappingStorage.shared.mappings.map(\.bundleID))

        runningApps = NSWorkspace.shared.runningApplications
            .filter { app in
                // Only regular apps (not background agents)
                app.activationPolicy == .regular &&
                app.bundleIdentifier != nil &&
                app.bundleIdentifier != Bundle.main.bundleIdentifier &&
                !existingBundleIDs.contains(app.bundleIdentifier!)
            }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
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
